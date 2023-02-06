// Ensure ThreeJS is in global scope for the 'examples/'
global.THREE = require("three");

const canvasSketch = require("canvas-sketch");

import frag from "./fragment.glsl";
import vert from "./vertex.glsl";

const matcap_shiny_red = "./resources/matcap_shiny_red.jpeg";
const matcap_pink = "./resources/matcap_pink.jpeg";

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

  // Setup a material
  const material = new THREE.ShaderMaterial({
    vertexShader: vert,
    fragmentShader: frag,
    uniforms: {
      resolution: { value: new THREE.Vector4() },
      mouseCoords: { value: new THREE.Vector2() },
      // mbIterations: 1,
      mbBailout: 6.0,
      mbPower: 6.0,
      time: { value: 0.0 },
      matcap: {
        value: textureLoader.load(matcap_shiny_red),
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
        material.uniforms.mouseCoords.value.x =
          (e.pageX / viewportWidth) * 2 - 1;
        material.uniforms.mouseCoords.value.y =
          (e.pageY / viewportHeight) * 2 - 1;
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
        console.log("in if:", material.uniforms.resolution);
      }
    },
    // Update & render your scene here
    render({ time }) {
      material.uniforms.time.value = time;
      renderer.render(scene, camera);
    },
    // Dispose of events & renderer for cleaner hot-reloading
    unload() {
      renderer.dispose();
    },
  };
};

canvasSketch(sketch, settings);
