shader_type spatial;

render_mode unshaded;

uniform sampler2D screen_tex : hint_screen_texture;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	mat4 my_view_mat = mat4(
			vec4(1, 0, 0, 0),
			vec4(0, 1, 0, 0),
			vec4(0, 0, 1, 0),
			vec4(0, 0, 0, 1)
		);
	my_view_mat *= mat4(
			vec4(1, 0, 0, 433),
			vec4(0, 1, 0, 32),
			vec4(0, 0, 1, 12),
			vec4(0, 0, 0, 1)
		);
	vec3 uv = (my_view_mat * vec4(SCREEN_UV, 0.0, 1.0)).xyz;
	ALBEDO = texture(screen_tex, uv.rg).xyz;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
