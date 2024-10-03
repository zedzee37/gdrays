#[compute]
#version 450

layout(local_size_x = 8, local_size_y = 8, local_size_z = 1) in;

layout(rgba32f, binding = 0) uniform image2D image;

layout(set = 0, binding = 1, std430) restrict buffer CameraData {
    mat4 camera_matrix;
} camera_data;

layout(set = 0, binding = 2, std430) restrict buffer Parameters {
    int max_bounces;
    int pixels_per_ray;
} params;

struct Material {
    vec3 color;
    float emission_strength;
    vec3 emission_color;
};

struct Sphere {
    float radius;
    vec3 origin;
    Material emission_color;
};

layout(set = 0, binding = 3, std430) restrict buffer Spheres {
    Sphere data[];
} spheres;

void main() {
	ivec2 image_size = imageSize(image);
	vec2 uv = vec2((gl_GlobalInvocationID.xy) / vec2(image_size));

    imageStore(image, ivec2(gl_GlobalInvocationID.xy), vec4(uv.x, uv.y, 0.0, 1.0));
}
