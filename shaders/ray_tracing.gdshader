shader_type spatial;

render_mode unshaded;

uniform sampler2D depthTexture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float[256] sphereRadiuses;
uniform vec3[256] spherePositions;
uniform vec3[256] sphereColors : source_color;
uniform int sphereCount = 0;
uniform sampler2D skyGradient;

struct Ray {
	vec3 origin;
	vec3 direction;
};

struct HitInfo {
	vec3 hitPos;
	bool hit;
	float dst;
};

HitInfo checkSphere(Ray ray, vec3 pos, float radius) {
	HitInfo hitInfo;
	vec3 rayOrigin = ray.origin - pos;

	float a = dot(ray.direction, ray.direction);
	float b = 2.0 * dot(rayOrigin, ray.direction);
	float c = dot(rayOrigin, rayOrigin) - radius * radius;

	float discriminant = b * b - 4.0 * a * c;

	if (discriminant >= 0.0) {
		float dst = -b - sqrt(discriminant) / (2.0 * a);

		if (dst >= 0.0) {
			hitInfo.hit = true;
			hitInfo.dst = dst;
			
			vec3 hitPos = rayOrigin + ray.direction * dst;
			hitInfo.hitPos = hitPos;
			return hitInfo;
		}
	}
	
	hitInfo.hit = false;
	return hitInfo;
}

vec3 raycastSphere(Ray ray) {
	float closestDst = 1000000000.0;
	int closestSphere = -1;

	for (int i = 0; i < sphereCount; i++) {
		float radius = sphereRadiuses[i];
		vec3 position = spherePositions[i];
		
		HitInfo sphereHitInfo = checkSphere(ray, position, radius);

		if (sphereHitInfo.hit) {
			if (sphereHitInfo.dst < closestDst) {
				closestDst = sphereHitInfo.dst;
				closestSphere = i;
			}
		}
	}

	if (closestSphere == -1) {
		float yDir = (ray.direction.y + 1.0) / 2.0;
		vec4 col = texture(skyGradient, vec2(yDir));
		return col.rgb;
	}

	return sphereColors[closestSphere];
}

void fragment() {
	vec3 worldPos = (vec4(VERTEX, 1.0) * VIEW_MATRIX).xyz;

	Ray ray;
	ray.origin = CAMERA_POSITION_WORLD;
	ray.direction = normalize(worldPos);

	ALBEDO = raycastSphere(ray);
}

