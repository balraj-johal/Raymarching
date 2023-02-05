
varying vec2 vUv;

#define PI 3.1415926;

void main () {
  vec4 mvPosition = modelViewMatrix * vec4( position.xyz, 1.0 );
  gl_Position = projectionMatrix * mvPosition;

  vUv = uv;
}
