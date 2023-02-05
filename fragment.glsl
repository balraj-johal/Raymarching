varying vec2 vUv;
uniform sampler2D noiseTex;
uniform sampler2D touchTex;

void main () {
  vec3 color = vec3(0.388, 0.333, 0.184);

  gl_FragColor = vec4(vUv, 0.0, 1.0);
}