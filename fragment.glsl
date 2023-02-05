varying vec2 vUv;

uniform vec4 resolution;

const int noInterations = 256;
const float epsilson = 0.001;
const vec2 h = vec2(epsilson, 0.0);
const vec3 lightPos = vec3(1.0);

// Signed Distance Field of a torus
float sdfTorus(vec3 position, vec2 t) {
  vec2 q = vec2(length(position.xz) - t.x, position.y);
  return length(q) - t.y;
}

// Signed Distance Field of a sphere
float sdfSphere(vec3 position, float radius) {
  return length(position) - radius;
}

// build scene
float sdf(vec3 position) {
  return sdfSphere(position, 0.2);
}

vec3 getNormalAtPoint(vec3 point) {
  return normalize(vec3(sdf(point + h.xyy) - sdf(point - h.xyy),
                        sdf(point + h.yxy) - sdf(point - h.yxy),
                        sdf(point + h.yyx) - sdf(point - h.yyx)));
}

void main () {
  vec3 colorNice = vec3(0.388, 0.333, 0.184);
  vec3 color = vec3(0.0);
  vec3 cameraPos = vec3(0.0, 0.0, 2.0);
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