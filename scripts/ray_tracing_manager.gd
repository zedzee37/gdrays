class_name RayTracingManager
extends Camera3D


static var instance: RayTracingManager


@onready var material: ShaderMaterial = $RayTracingShader.mesh.material


var spheres: Array[RayTracedSphere] = []
var rot: float = 0


func _enter_tree() -> void:
	instance = self

func _input(event: InputEvent) -> void:
	if event.is_action("ui_left"):
		rot += 0.01
		rot = fmod(rot, 2 * PI)


func _process(_delta: float) -> void:
	material.set_shader_parameter("sphereRadiuses", get_radiuses())
	material.set_shader_parameter("spherePositions", get_sphere_positions())
	material.set_shader_parameter("sphereColors", get_sphere_colors())
	material.set_shader_parameter("sphereCount", spheres.size())
	
	position.x = cos(rot) * 10
	position.z = sin(rot) * 10
	look_at(Vector3(0, 0, 0))


func get_radiuses() -> PackedFloat64Array:
	var radiuses := PackedFloat64Array()
	
	for sphere: RayTracedSphere in spheres:
		radiuses.append(sphere.radius)
	
	return radiuses


func get_sphere_positions() -> PackedVector3Array:
	var positions := PackedVector3Array()

	for sphere: RayTracedSphere in spheres:
		positions.append(sphere.global_position)
	
	return positions


func get_sphere_colors() -> PackedColorArray:
	var colors := PackedColorArray()

	for sphere: RayTracedSphere in spheres:
		colors.append(sphere.color)
	
	return colors


func add_sphere(sphere: RayTracedSphere) -> void:
	spheres.append(sphere)
