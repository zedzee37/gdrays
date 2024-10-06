shader_type spatial;

render_mode unshaded, world_vertex_coords;

uniform sampler2D depthTexture : hint_depth_texture, repeat_disable, filter_nearest;
uniform float[256] sphereRadiuses;
uniform vec3[256] spherePositions;
uniform vec3[256] sphereColors : source_color;
uniform float[256] sphereLighting;
uniform vec3[256] sphereEmission;
uniform int sphereCount = 0;
uniform sampler2D skyGradient;

uniform uint rayBounces = 2;

struct Ray {
	vec3 origin;
	vec3 direction;
};

struct Material {
	vec3 color;
	float emissionStrength;
	vec3 emissionColor;
};

struct HitInfo {
	vec3 hitPos;
	bool hit;
	float dst;
	vec3 normal;
	Material material;
};

float random(inout vec2 randomState) {
    float rand = fract(sin(dot(randomState.xy,
        vec2(12.9898,78.233))) * 43758.5453123);

	randomState = vec2(rand);
	return rand;
}


float randomNormal(inout vec2 state) {
	float theta = 2.0 * 3.1415926 * float(random(state));
	float rho = sqrt(-2.0 * log(float(random(state))));
	return rho * cos(theta);
}

vec3 randomDirection(inout vec2 state) {
	float x = randomNormal(state);
	float y = randomNormal(state);
	float z = randomNormal(state);
	return vec3(x, y, z);
}

HitInfo checkSphere(Ray ray, vec3 pos, float radius) {
	HitInfo hitInfo;
	vec3 rayOrigin = ray.origin - pos;

	float a = dot(ray.direction, ray.direction);
	float b = 2.0 * dot(rayOrigin, ray.direction);
	float c = dot(rayOrigin, rayOrigin) - radius * radius;

	float discriminant = b * b - 4.0 * a * c;

	if (discriminant >= 0.0) {
		float dst = (-b - sqrt(discriminant)) / (2.0 * a);

		if (dst >= 0.0) {
			hitInfo.hit = true;
			hitInfo.dst = dst;

			vec3 hitPos = rayOrigin + ray.direction * dst;
			hitInfo.hitPos = hitPos;

			vec3 normal = normalize(hitPos - pos);
			hitInfo.normal = normal;
			return hitInfo;
		}
	}

	hitInfo.hit = false;
	return hitInfo;
}


HitInfo raycastSphere(Ray ray) {
	Ray currentRay = ray;
	float closestDst = 1000000000.0;
	int closestSphere = -1;
	HitInfo closestSphereHitInfo;

	for (int i = 0; i < sphereCount; i++) {
		float radius = sphereRadiuses[i];
		vec3 position = spherePositions[i];

		HitInfo sphereHitInfo = checkSphere(currentRay, position, radius);

		if (sphereHitInfo.hit) {
			if (sphereHitInfo.dst < closestDst) {
				closestDst = sphereHitInfo.dst;
				closestSphere = i;
				closestSphereHitInfo = sphereHitInfo;
			}
		}
	}

	if (closestSphere == -1) {
		HitInfo empty;
		empty.hit = false;
		return empty;
	}

	Material material;
	material.color = sphereColors[closestSphere];
	material.emissionStrength = sphereLighting[closestSphere];
	material.emissionColor = sphereEmission[closestSphere];
	closestSphereHitInfo.material = material;
	return closestSphereHitInfo;
}

vec3 trace(Ray ray, inout vec2 randomState) {
	vec3 rayColor = vec3(1.0);
	vec3 emittedLight = vec3(0.0);

	for (uint i = uint(0); i <= rayBounces; i++) {
		HitInfo hitInfo = raycastSphere(ray);

		if (!hitInfo.hit) {
			return emittedLight;
		}

		ray.origin = hitInfo.hitPos;
		ray.direction = randomDirection(randomState);

		if (dot(ray.direction, hitInfo.normal) < 0.0) {
			ray.direction *= vec3(-1.0);
		}

		Material material = hitInfo.material;
		vec3 currentLight = material.emissionColor * vec3(material.emissionStrength);

		emittedLight += currentLight * rayColor;
		rayColor *= material.color;
	}

	return emittedLight;
}

void fragment() {
	vec3 worldPos = (vec4(VERTEX, 1.0) * VIEW_MATRIX).xyz;
	vec2 uv = UV;

	Ray ray;
	ray.origin = CAMERA_POSITION_WORLD;
	ray.direction = normalize(worldPos);

	vec3 incomingLight = vec3(0.0);

	for (int i = 0; i < 10; i++) {
		incomingLight += trace(ray, uv);
	}

	ALBEDO = incomingLight / 10.0;
}
