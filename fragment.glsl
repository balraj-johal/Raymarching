varying vec2 vUv;

uniform vec4 resolution;
uniform vec2 mouseCoords;
uniform sampler2D matcap;

const int noInterations = 256;
const float epsilson = 0.005;
const vec2 h = vec2(epsilson, 0.0);
const vec3 lightPos = vec3(1.0);

//mandlebulb constants
const int mbIterations = 8;
const float mbBailout = 1.000225;
const float mbPower = 5.0;
uniform float time;


// half the following off IQUILEZ so ty!

// https://iquilezles.org/articles/smin/
float smin( float a, float b, float k )
{
    float h = clamp( 0.5+0.5*(b-a)/k, 0.0, 1.0 );
    return mix( b, a, h ) - k*h*(1.0-h);
}

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
  float power = (sin(time * 0.25) + 1.5) * mbPower;

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

// also nicked off someone: 
vec2 getMatcap(vec3 eye, vec3 normal) {
  vec3 reflected = reflect(eye, normal);
  float m = 2.8284271247461903 * sqrt( reflected.z+1.0 );
  return reflected.xy / m + 0.5;
}

// rotations from: https://gist.github.com/yiwenl/3f804e80d0930e34a0b33359259b556c
mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;
    return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                0.0,                                0.0,                                0.0,                                1.0);
}
vec3 rotate(vec3 v, vec3 axis, float angle) {
	mat4 m = rotationMatrix(axis, angle);
	return (m * vec4(v, 1.0)).xyz;
}

// Signed Distance Field of a torus
float sdfRotatingTorus(vec3 position, vec2 t) {
  vec2 q = vec2(length(position.xz) - t.x, position.y);
  vec3 rotatedOverTime = rotate(position, vec3(0.0, 1.0, 1.0), time);
  return length(q) - t.y;
}
// infinite repetition: https://iquilezles.org/articles/distfunctions/
vec3 infiniteTorus( vec3 p, vec3 c )
{
    vec3 q = mod(p+0.5*c,c)-0.5*c;
    return q;
}

// build scene
float sdf(vec3 position) {
  vec3 correctedMouse = vec3(mouseCoords.xy * resolution.zw, 0.0);
  float movingSphere = sdfSphere(position + correctedMouse, 0.2);
  vec3 rotatedOverTime = rotate(position, vec3(0.0, 1.0, 1.0), time);
  // float torus = sdfTorus(rotatedOverTime, vec2(0.35, 0.05));
  vec3 toruses = infiniteTorus(position, vec3(1.0));
  vec3 rotatedTouruses = rotate(toruses, vec3(0.0, 1.0, 1.0), time);
  float sdfToruses = sdfTorus(rotatedTouruses, vec2(0.35, 0.05));

  float scene = 1.0;
  scene = smin(scene, movingSphere, 0.1);
  // scene = smin(scene, torus, 0.1);
  scene = smin(scene, sdfToruses, 0.1);
  return scene;
}

// also nicked
vec3 getNormalAtPoint(vec3 point) {
  return normalize(vec3(sdf(point + h.xyy) - sdf(point - h.xyy),
                        sdf(point + h.yxy) - sdf(point - h.yxy),
                        sdf(point + h.yyx) - sdf(point - h.yyx)));
}

void main () {
  vec3 colorNice = vec3(0.388, 0.333, 0.184);
  vec3 color = vec3(0.0);
  vec3 cameraPos = vec3(0.0, 0.0, 2.5);
  vec2 correctedUV = (vUv - vec2(0.5)) * resolution.zw;
  vec3 rayDir = normalize(vec3(correctedUV, -1.0)); // -1 z value is to ensure the ray is cast from camera to origin

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
    vec2 matcapUV = getMatcap(rayDir, normal);

    color = texture2D(matcap, matcapUV).rgb;
  }

  gl_FragColor = vec4(color, 1.0);
}