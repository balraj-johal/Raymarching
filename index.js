// Ensure ThreeJS is in global scope for the 'examples/'
global.THREE = require("three");

const canvasSketch = require("canvas-sketch");

import frag from "./fragment.glsl";
import vert from "./vertex.glsl";

const matcap_shiny_red = "./resources/matcap_shiny_red.jpeg";
const matcap_pink = "./resources/matcap_pink.jpeg";
const matcap_green = "./resources/matcap_green.png";
const matcap_angel = "./resources/matcap_angel.png";
const matcap_solar = "./resources/matcap_solar.png";

const lerp = (a, b, t) => {
  return a + (b - a) * t;
};

const settings = {
  // Make the loop animated
  animate: true,
  // Get a WebGL canvas rather than 2D
  context: "webgl",
};

const sketch = ({ context }) => {
  // Create a renderer
  const renderer = new THREE.WebGLRenderer({
    canvas: context.canvas,
  });

  const textureLoader = new THREE.TextureLoader();

  // WebGL background color
  renderer.setClearColor("#000", 1);

  const frustumSize = 10;

  // Setup a camera
  const camera = new THREE.OrthographicCamera(
    frustumSize / -2,
    frustumSize / 2,
    frustumSize / 2,
    frustumSize / -2,
    -1000,
    1000
  );
  camera.position.set(0, 0, -5);
  camera.lookAt(new THREE.Vector3());

  // Setup your scene
  const scene = new THREE.Scene();

  // Setup a geometry
  const geometry = new THREE.PlaneGeometry(frustumSize, frustumSize, 1, 1);

  const sphere1 = new THREE.Vector2();
  const sphere2 = new THREE.Vector2();
  const sphere3 = new THREE.Vector2();
  const mouse = new THREE.Vector2();
  // Setup a material
  const material = new THREE.ShaderMaterial({
    vertexShader: vert,
    fragmentShader: frag,
    uniforms: {
      resolution: { value: new THREE.Vector4() },
      sphere1: { value: sphere1 },
      sphere2: { value: sphere2 },
      sphere3: { value: sphere3 },
      // mbIterations: 1,
      mbBailout: 6.0,
      mbPower: 6.0,
      time: { value: 0.0 },
      matcap: {
        value: textureLoader.load(matcap_angel),
      },
    },
    side: THREE.DoubleSide,
  });
  material.uniformsNeedUpdate = true;

  // Setup a mesh with geometry + material
  const mesh = new THREE.Mesh(geometry, material);
  scene.add(mesh);

  // draw each frame
  return {
    // Handle resize events here
    resize({ pixelRatio, viewportWidth, viewportHeight }) {
      renderer.setPixelRatio(pixelRatio);
      renderer.setSize(viewportWidth, viewportHeight, false);
      camera.aspect = viewportWidth / viewportHeight;
      camera.updateProjectionMatrix();

      const mouseListener = (e) => {
        mouse.x = (e.pageX / viewportWidth) * 2 - 1;
        mouse.y = (e.pageY / viewportHeight) * 2 - 1;
      };
      window.removeEventListener("mousemove", mouseListener);

      window.addEventListener("mousemove", mouseListener);

      if (material.uniforms.resolution) {
        material.uniforms.resolution.value.x = viewportWidth;
        material.uniforms.resolution.value.y = viewportHeight;
        let a1;
        let a2;
        if (viewportHeight / viewportWidth > 1) {
          a1 = viewportWidth / viewportHeight;
          a2 = 1;
        } else {
          a1 = 1;
          a2 = viewportHeight / viewportWidth;
        }
        material.uniforms.resolution.value.z = a1;
        material.uniforms.resolution.value.w = a2;
      }
    },
    // Update & render your scene here
    render({ time }) {
      material.uniforms.time.value = time;

      sphere1.x = lerp(sphere1.x, mouse.x, 0.05);
      sphere1.y = lerp(sphere1.y, mouse.y, 0.05);

      sphere2.x = lerp(sphere2.x, sphere1.x, 0.1);
      sphere2.y = lerp(sphere2.y, sphere1.y, 0.1);

      sphere3.x = lerp(sphere3.x, sphere2.x, 0.1);
      sphere3.y = lerp(sphere3.y, sphere2.y, 0.1);

      renderer.render(scene, camera);
    },
    // Dispose of events & renderer for cleaner hot-reloading
    unload() {
      renderer.dispose();
    },
  };
};

canvasSketch(sketch, settings);
