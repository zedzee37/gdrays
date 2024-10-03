class_name RayTracingManagerNew
extends Camera3D


static var instance: RayTracingManagerNew


@export var texture_rect: TextureRect
@export var max_bounces: int = 2
@export var rays_per_pixel: int = 1


var image_size : Vector2i
var spheres: Array[RayTracedSphere] = []
var rot: float = 0
var rd := RenderingServer.create_local_rendering_device()
var shader: RID
var pipeline: RID
var output_tex: RID
var uniform_set
var bindings
var output_image: Image


func _enter_tree() -> void:
	instance = self


func _ready() -> void:
	image_size.x = ProjectSettings.get_setting("display/window/size/viewport_width")
	image_size.y = ProjectSettings.get_setting("display/window/size/viewport_height")

	setup_compute()


func _input(event: InputEvent) -> void:
	if event.is_action("ui_left"):
		rot += 0.04
		rot = fmod(rot, 2 * PI)


func _process(_delta: float) -> void:
	position.x = cos(rot) * 10
	position.z = sin(rot) * 10
	position.y = 10
	look_at(Vector3(0, 0, 0))

	update_compute()
	render()


func setup_compute() -> void:
	var shader_file = load("res://shaders/ray_tracing_new.glsl")
	var spirv = shader_file.get_spirv()
	shader = rd.shader_create_from_spirv(spirv)
	pipeline = rd.compute_pipeline_create(shader)

	# Output image
	var fmt := RDTextureFormat.new()
	fmt.width = image_size.x
	fmt.height = image_size.y
	fmt.format = RenderingDevice.DATA_FORMAT_R32G32B32A32_SFLOAT
	fmt.usage_bits = RenderingDevice.TEXTURE_USAGE_CAN_UPDATE_BIT | RenderingDevice.TEXTURE_USAGE_STORAGE_BIT | RenderingDevice.TEXTURE_USAGE_CAN_COPY_FROM_BIT

	var view := RDTextureView.new()
	output_image = Image.create(image_size.x, image_size.y, false, Image.FORMAT_RGBAF)
	output_tex = rd.texture_create(fmt, view, [output_image.get_data()])

	var output_tex_uniform := RDUniform.new()
	output_tex_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_IMAGE
	output_tex_uniform.binding = 0
	output_tex_uniform.add_id(output_tex)

	# Camera Matrix
	var camera_matrix := get_camera_matrix()
	var camera_matrix_buffer = rd.storage_buffer_create(camera_matrix.size(), camera_matrix)

	var camera_matrix_uniform = RDUniform.new()
	camera_matrix_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	camera_matrix_uniform.binding = 1
	camera_matrix_uniform.add_id(camera_matrix_buffer)

	var parameters := get_parameters()
	var parameters_buffer := rd.storage_buffer_create(parameters.size(), parameters)
	var parameters_uniform := RDUniform.new()
	parameters_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	parameters_uniform.binding = 2
	parameters_uniform.add_id(parameters_buffer)

	var packed_spheres := get_spheres()
	var spheres_buffer = rd.storage_buffer_create(spheres.size(), packed_spheres)
	var spheres_uniform = RDUniform.new()
	spheres_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	spheres_uniform.binding = 3
	spheres_uniform.add_id(spheres_buffer)

	bindings = [
		output_tex_uniform,
		camera_matrix_uniform,
		parameters_uniform,
		spheres_uniform
	]
	uniform_set = rd.uniform_set_create(bindings, shader, 0)


func update_compute() -> void:
	var camera_matrix := get_camera_matrix()
	var camera_matrix_buffer = rd.storage_buffer_create(camera_matrix.size(), camera_matrix)

	var camera_matrix_uniform = RDUniform.new()
	camera_matrix_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	camera_matrix_uniform.binding = 1
	camera_matrix_uniform.add_id(camera_matrix_buffer)

	var packed_spheres := get_spheres()
	var spheres_buffer = rd.storage_buffer_create(spheres.size(), packed_spheres)
	var spheres_uniform = RDUniform.new()
	spheres_uniform.uniform_type = RenderingDevice.UNIFORM_TYPE_STORAGE_BUFFER
	spheres_uniform.binding = 3
	spheres_uniform.add_id(spheres_buffer)

	bindings[1] = camera_matrix_uniform
	bindings[3] = spheres_uniform
	uniform_set = rd.uniform_set_create(bindings, shader, 0)


func render() -> void:
	var compute_list := rd.compute_list_begin()

	rd.compute_list_bind_compute_pipeline(compute_list, pipeline)
	rd.compute_list_bind_uniform_set(compute_list, uniform_set, 0)

	@warning_ignore("integer_division")
	rd.compute_list_dispatch(compute_list, image_size.x / 8, image_size.y / 8, 1)

	rd.compute_list_end()
	rd.submit()

	rd.sync()

	var byte_data : PackedByteArray = rd.texture_get_data(output_tex, 0)
	output_image.set_data(image_size.x, image_size.y, false, Image.FORMAT_RGBAF, byte_data)
	texture_rect.texture = ImageTexture.create_from_image(output_image)


func add_sphere(sphere: RayTracedSphere) -> void:
	spheres.append(sphere)


func get_camera_matrix() -> PackedByteArray:
	var project = get_camera_projection()
	return PackedFloat32Array([
			project.x.x, project.x.y, project.x.z, project.x.w,
			project.y.x, project.y.y, project.y.z, project.y.w,
			project.z.x, project.z.y, project.z.z, project.z.w,
			project.w.x, project.w.y, project.w.z, project.w.w
		]).to_byte_array()


func get_parameters() -> PackedByteArray:
	return PackedByteArray([
		max_bounces,
		rays_per_pixel
	])


func get_spheres() -> PackedByteArray:
	var packed_spheres := []

	for sphere: RayTracedSphere in spheres:
		var material = PackedByteArray([
			sphere.color,
			sphere.light_intensity,
			sphere.light_color
		])
		packed_spheres.append(PackedByteArray([
			sphere.radius,
			sphere.global_position,
			material
		]))
	
	return PackedByteArray(packed_spheres)
	
