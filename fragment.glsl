varying vec2 vUv;

uniform vec4 resolution;

const int noInterations = 256;
const float epsilson = 0.005;
const vec2 h = vec2(epsilson, 0.0);
const vec3 lightPos = vec3(1.0);

//mandlebulb constants
const int mbIterations = 8;
const float mbBailout = 1.002;
const float mbPower = 5.0;
// uniform int mbIterations;
// uniform float mbBailout;
// uniform float mbPower;
uniform float time;

// Signed Distance Field of a torus
float sdfTorus(vec3 position, vec2 t) {
  vec2 q = vec2(length(position.xz) - t.x, position.y);
  return length(q) - t.y;
}

// Signed Distance Field of a sphere
float sdfSphere(vec3 position, float radius) {
  return length(position) - radius;
}

float sdfMandlebulb(vec3 pos) {
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
  float power = (sin(time * 0.5) + 1.5) * mbPower;

	for (int i = 0; i < mbIterations ; i++) {
		r = length(z);
		if (r > mbBailout) break;
		
		// convert to polar coordinates
		float theta = acos(z.z / r);
		float phi = atan(z.y, z.x);
		dr = pow(r, power - 1.0) * power * dr + 1.0;
		
		// scale and rotate the point
		float zr = pow(r, power);
		theta = theta * power;
		phi = phi * power;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z+=pos;
	}
	return 0.5 * log(r) * r/dr;
}

// build scene
float sdf(vec3 position) {
  float sphere = sdfSphere(position, 0.2);
  float mandlebulb = sdfMandlebulb(position);
  return mandlebulb;
}

vec3 getNormalAtPoint(vec3 point) {
  return normalize(vec3(sdf(point + h.xyy) - sdf(point - h.xyy),
                        sdf(point + h.yxy) - sdf(point - h.yxy),
                        sdf(point + h.yyx) - sdf(point - h.yyx)));
}

void main () {
  vec3 colorNice = vec3(0.388, 0.333, 0.184);
  vec3 color = vec3(0.0);
  vec3 cameraPos = vec3(0.0, 0.0, 2.5);
  vec3 rayDir = normalize(vec3((vUv - vec2(0.5)) * vec2(1, 1), -1.0)); // -1 z value is to ensure the ray is cast from camera to origin

  vec3 rayPos = cameraPos;
  float t = 0.0;
  float tMax = 5.0;
  float closenessValue = 0.0001;

  for (int i = 0; i < noInterations; i++) {
    vec3 pos = cameraPos + t * rayDir;
    float dist = sdf(pos);
    if (dist < closenessValue || t > tMax) break;
    t += dist;
  }

  if (t < tMax) {
    vec3 pos = cameraPos + t * rayDir;
    vec3 normal = getNormalAtPoint(pos);
    float diff = dot(lightPos, normal);
    color = vec3(diff);
  }

  gl_FragColor = vec4(color, 1.0);
  // if (resolution.y > 0.0) gl_FragColor = vec4(resolution);
}