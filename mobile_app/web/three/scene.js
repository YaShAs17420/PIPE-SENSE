import * as THREE from 'https://esm.sh/three@0.180.0';
import { OrbitControls } from 'https://esm.sh/three@0.180.0/examples/jsm/controls/OrbitControls.js';

// ======================================================
// PIPE-SENSE 3D ENGINE
// ======================================================

let scene;
let camera;
let renderer;
let controls;
let container;

let animationFrameId = null;
let resizeObserver = null;

const waterParticles = [];
const leakParticles = [];
const zoneObjects = [];
const sensorObjects = [];

let currentLeakZone = null;
let selectedZone = null;
let systemLeakDetected = false;

let currentSensorState = {
  yfFlowRate: 0,
  zjFlowRate: 0,
  vibration1: 0,
  vibration2: 0,
};

// ======================================================
// COLORS
// ======================================================

const COLORS = {
  background: 0xeaf5ef,

  floor: 0xdcebe3,
  platform: 0xf8fbf9,

  pipe: 0xf9fcfa,
  pipeDark: 0x17251f,

  water: 0x20aee8,
  waterLight: 0x86e4ff,

  sensorGreen: 0x65e8ad,
  sensorBlue: 0x50d9ef,

  normal: 0x65e8ad,
  warning: 0xff5870,
  selected: 0x35bde9,

  tankBlue: 0x57ccef,

  pumpBody: 0x182a24,
  pumpDark: 0x0b1713,
  pumpMetal: 0x30433c,
};

// ======================================================
// DIMENSIONS
// ======================================================

const PIPE_Y = 1.45;
const PIPE_LENGTH = 18;
const PIPE_RADIUS = 0.62;

const ZONE_POSITIONS = [
  -6.0,
  0,
  6.0,
];

// ======================================================
// CONTAINER
// ======================================================

function getContainer() {
  return document.getElementById(
    'pipe-sense-three-container'
  );
}

// ======================================================
// CREATE SCENE
// ======================================================

function createScene() {
  container = getContainer();

  if (!container) {
    setTimeout(
      createScene,
      250
    );

    return;
  }

  if (renderer) {
    return;
  }

  // --------------------------------------------------
  // SCENE
  // --------------------------------------------------

  scene =
    new THREE.Scene();

  scene.background =
    new THREE.Color(
      COLORS.background
    );

  // --------------------------------------------------
  // CAMERA
  // --------------------------------------------------

  const width =
    Math.max(
      container.clientWidth,
      1
    );

  const height =
    Math.max(
      container.clientHeight,
      1
    );

  camera =
    new THREE.PerspectiveCamera(
      38,
      width / height,
      0.1,
      1000
    );

  // Tank and pump appear on the LEFT.
  camera.position.set(
    -13,
    7.5,
    15
  );

  // --------------------------------------------------
  // RENDERER
  // --------------------------------------------------

  renderer =
    new THREE.WebGLRenderer({
      antialias: true,
      alpha: true,
      powerPreference:
        'high-performance',
    });

  renderer.setPixelRatio(
    Math.min(
      window.devicePixelRatio || 1,
      2
    )
  );

  renderer.setSize(
    width,
    height
  );

  renderer.shadowMap.enabled =
    true;

  renderer.shadowMap.type =
    THREE.PCFSoftShadowMap;

  renderer.outputColorSpace =
    THREE.SRGBColorSpace;

  renderer.toneMapping =
    THREE.ACESFilmicToneMapping;

  renderer.toneMappingExposure =
    1.05;

  container.innerHTML = '';

  container.appendChild(
    renderer.domElement
  );

  renderer.domElement.style.display =
    'block';

  renderer.domElement.style.width =
    '100%';

  renderer.domElement.style.height =
    '100%';

  renderer.domElement.style.touchAction =
    'none';

  // --------------------------------------------------
  // ORBIT CONTROLS
  // --------------------------------------------------

  controls =
    new OrbitControls(
      camera,
      renderer.domElement
    );

  controls.enableDamping =
    true;

  controls.dampingFactor =
    0.06;

  controls.minDistance =
    7;

  controls.maxDistance =
    30;

  controls.maxPolarAngle =
    Math.PI * 0.47;

  controls.target.set(
    0,
    0.75,
    0
  );

  // --------------------------------------------------
  // BUILD SCENE
  // --------------------------------------------------

  createLighting();

  createEnvironment();

  createPipeSystem();

  createWaterFlow();

  createLeakParticles();

  // --------------------------------------------------
  // RESIZE
  // --------------------------------------------------

  window.addEventListener(
    'resize',
    resize
  );

  if (
    'ResizeObserver' in
    window
  ) {
    resizeObserver =
      new ResizeObserver(
        () => {
          resize();
        }
      );

    resizeObserver.observe(
      container
    );
  }

  // --------------------------------------------------
  // START
  // --------------------------------------------------

  animate();
}

// ======================================================
// LIGHTING
// ======================================================

function createLighting() {
  const hemisphere =
    new THREE.HemisphereLight(
      0xffffff,
      0xb7cfc3,
      2.5
    );

  scene.add(
    hemisphere
  );

  const keyLight =
    new THREE.DirectionalLight(
      0xffffff,
      3.3
    );

  keyLight.position.set(
    -8,
    14,
    10
  );

  keyLight.castShadow =
    true;

  keyLight.shadow.mapSize.width =
    2048;

  keyLight.shadow.mapSize.height =
    2048;

  keyLight.shadow.camera.left =
    -22;

  keyLight.shadow.camera.right =
    22;

  keyLight.shadow.camera.top =
    20;

  keyLight.shadow.camera.bottom =
    -12;

  scene.add(
    keyLight
  );

  const fillLight =
    new THREE.DirectionalLight(
      0xd9f5ff,
      1.5
    );

  fillLight.position.set(
    10,
    7,
    8
  );

  scene.add(
    fillLight
  );

  const waterLight =
    new THREE.PointLight(
      0x8edcff,
      8,
      30
    );

  waterLight.position.set(
    -4,
    4,
    5
  );

  scene.add(
    waterLight
  );
}

// ======================================================
// ENVIRONMENT
// ======================================================

function createEnvironment() {
  // --------------------------------------------------
  // FLOOR
  // --------------------------------------------------

  const floorGeometry =
    new THREE.PlaneGeometry(
      42,
      25
    );

  const floorMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.floor,

      roughness:
        0.9,

      metalness:
        0,
    });

  const floor =
    new THREE.Mesh(
      floorGeometry,
      floorMaterial
    );

  floor.rotation.x =
    -Math.PI / 2;

  floor.position.y =
    -1.2;

  floor.receiveShadow =
    true;

  scene.add(
    floor
  );

  // --------------------------------------------------
  // PLATFORM
  // --------------------------------------------------

  const platformGeometry =
    new THREE.BoxGeometry(
      26,
      0.35,
      8
    );

  const platformMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.platform,

      roughness:
        0.72,

      metalness:
        0.02,
    });

  const platform =
    new THREE.Mesh(
      platformGeometry,
      platformMaterial
    );

  platform.position.set(
    0,
    -0.98,
    0
  );

  platform.receiveShadow =
    true;

  platform.castShadow =
    true;

  scene.add(
    platform
  );

  // --------------------------------------------------
  // GRID
  // --------------------------------------------------

  const grid =
    new THREE.GridHelper(
      36,
      36,
      0xc4d9d0,
      0xd7e6df
    );

  grid.position.y =
    -0.76;

  grid.material.transparent =
    true;

  grid.material.opacity =
    0.32;

  scene.add(
    grid
  );

  // --------------------------------------------------
  // BACK PANEL
  // --------------------------------------------------

  const backGeometry =
    new THREE.BoxGeometry(
      25,
      7.5,
      0.20
    );

  const backMaterial =
    new THREE.MeshStandardMaterial({
      color:
        0xe1e8e5,

      roughness:
        0.92,

      metalness:
        0,
    });

  const backPanel =
    new THREE.Mesh(
      backGeometry,
      backMaterial
    );

  backPanel.position.set(
    0,
    2.7,
    -4.1
  );

  backPanel.receiveShadow =
    true;

  scene.add(
    backPanel
  );
}

// ======================================================
// PIPE SYSTEM
// ======================================================

function createPipeSystem() {
  // --------------------------------------------------
  // MAIN PIPE
  // --------------------------------------------------

  const pipeGeometry =
    new THREE.CylinderGeometry(
      PIPE_RADIUS,
      PIPE_RADIUS,
      PIPE_LENGTH,
      64
    );

  const pipeMaterial =
    new THREE.MeshPhysicalMaterial({
      color:
        COLORS.pipe,

      transparent:
        true,

      opacity:
        0.76,

      roughness:
        0.22,

      metalness:
        0.03,

      clearcoat:
        0.5,

      clearcoatRoughness:
        0.18,

      transmission:
        0.08,

      depthWrite:
        false,
    });

  const pipe =
    new THREE.Mesh(
      pipeGeometry,
      pipeMaterial
    );

  pipe.rotation.z =
    Math.PI / 2;

  pipe.position.y =
    PIPE_Y;

  pipe.castShadow =
    true;

  pipe.receiveShadow =
    true;

  scene.add(
    pipe
  );

  createPipeEnds();

  createWaterTank();

  createFlowSensors();

  createVibrationSensors();

  createLeakZones();

  createPipeSupports();
}

// ======================================================
// PIPE ENDS
// ======================================================

function createPipeEnds() {
  const geometry =
    new THREE.CylinderGeometry(
      0.79,
      0.79,
      0.52,
      48
    );

  const material =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.pipeDark,

      roughness:
        0.30,

      metalness:
        0.55,
    });

  // LEFT END
  const left =
    new THREE.Mesh(
      geometry,
      material
    );

  left.rotation.z =
    Math.PI / 2;

  left.position.set(
    -9.15,
    PIPE_Y,
    0
  );

  left.castShadow =
    true;

  scene.add(
    left
  );

  // RIGHT END
  const right =
    new THREE.Mesh(
      geometry,
      material
    );

  right.rotation.z =
    Math.PI / 2;

  right.position.set(
    9.15,
    PIPE_Y,
    0
  );

  right.castShadow =
    true;

  scene.add(
    right
  );
}

// ======================================================
// WATER TANK + PUMP
// ======================================================

function createWaterTank() {
  // --------------------------------------------------
  // TANK
  // --------------------------------------------------

  const tankGeometry =
    new THREE.BoxGeometry(
      3.0,
      2.65,
      2.65
    );

  const tankMaterial =
    new THREE.MeshPhysicalMaterial({
      color:
        COLORS.tankBlue,

      transparent:
        true,

      opacity:
        0.34,

      roughness:
        0.10,

      metalness:
        0.03,

      transmission:
        0.12,

      depthWrite:
        false,
    });

  const tank =
    new THREE.Mesh(
      tankGeometry,
      tankMaterial
    );

  // LEFT SIDE
  tank.position.set(
    -12.0,
    -0.02,
    0
  );

  tank.castShadow =
    true;

  tank.receiveShadow =
    true;

  scene.add(
    tank
  );

  // --------------------------------------------------
  // WATER INSIDE TANK
  // --------------------------------------------------

  const waterGeometry =
    new THREE.BoxGeometry(
      2.55,
      1.65,
      2.25
    );

  const waterMaterial =
    new THREE.MeshPhysicalMaterial({
      color:
        COLORS.water,

      transparent:
        true,

      opacity:
        0.78,

      roughness:
        0.03,

      metalness:
        0,

      depthWrite:
        false,
    });

  const tankWater =
    new THREE.Mesh(
      waterGeometry,
      waterMaterial
    );

  tankWater.position.set(
    -12.0,
    -0.48,
    0
  );

  scene.add(
    tankWater
  );

  // --------------------------------------------------
  // TANK OUTLET PIPE
  // --------------------------------------------------

  const outletGeometry =
    new THREE.CylinderGeometry(
      0.28,
      0.28,
      0.90,
      28
    );

  const outletMaterial =
    new THREE.MeshStandardMaterial({
      color:
        0x253a33,

      roughness:
        0.30,

      metalness:
        0.45,
    });

  const tankOutlet =
    new THREE.Mesh(
      outletGeometry,
      outletMaterial
    );

  tankOutlet.rotation.z =
    Math.PI / 2;

  tankOutlet.position.set(
    -10.45,
    -0.05,
    0
  );

  tankOutlet.castShadow =
    true;

  scene.add(
    tankOutlet
  );

  // --------------------------------------------------
  // PUMP GROUP
  // --------------------------------------------------

  const pumpGroup =
    new THREE.Group();

  pumpGroup.position.set(
    -9.45,
    0.30,
    0
  );

  // --------------------------------------------------
  // MOTOR BODY
  // --------------------------------------------------

  const motorGeometry =
    new THREE.CylinderGeometry(
      0.58,
      0.58,
      1.70,
      40
    );

  const motorMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.pumpBody,

      roughness:
        0.25,

      metalness:
        0.58,
    });

  const motor =
    new THREE.Mesh(
      motorGeometry,
      motorMaterial
    );

  motor.rotation.z =
    Math.PI / 2;

  motor.castShadow =
    true;

  pumpGroup.add(
    motor
  );

  // --------------------------------------------------
  // REAR CAP
  // --------------------------------------------------

  const rearCapGeometry =
    new THREE.CylinderGeometry(
      0.63,
      0.63,
      0.20,
      40
    );

  const rearCapMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.pumpDark,

      roughness:
        0.28,

      metalness:
        0.65,
    });

  const rearCap =
    new THREE.Mesh(
      rearCapGeometry,
      rearCapMaterial
    );

  rearCap.rotation.z =
    Math.PI / 2;

  rearCap.position.x =
    -0.95;

  rearCap.castShadow =
    true;

  pumpGroup.add(
    rearCap
  );

  // --------------------------------------------------
  // FRONT PUMP HEAD
  // --------------------------------------------------

  const headGeometry =
    new THREE.CylinderGeometry(
      0.67,
      0.67,
      0.42,
      40
    );

  const head =
    new THREE.Mesh(
      headGeometry,
      rearCapMaterial
    );

  head.rotation.z =
    Math.PI / 2;

  head.position.x =
    0.98;

  head.castShadow =
    true;

  pumpGroup.add(
    head
  );

  // --------------------------------------------------
  // PUMP BASE
  // --------------------------------------------------

  const baseGeometry =
    new THREE.BoxGeometry(
      2.5,
      0.20,
      1.25
    );

  const baseMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.pumpMetal,

      roughness:
        0.45,

      metalness:
        0.35,
    });

  const base =
    new THREE.Mesh(
      baseGeometry,
      baseMaterial
    );

  base.position.y =
    -0.73;

  base.castShadow =
    true;

  pumpGroup.add(
    base
  );

  // --------------------------------------------------
  // PUMP FEET
  // --------------------------------------------------

  const footGeometry =
    new THREE.BoxGeometry(
      0.30,
      0.32,
      0.65
    );

  [-0.78, 0.78].forEach(
    (x) => {
      const foot =
        new THREE.Mesh(
          footGeometry,
          baseMaterial
        );

      foot.position.set(
        x,
        -0.98,
        0
      );

      foot.castShadow =
        true;

      pumpGroup.add(
        foot
      );
    }
  );

  // --------------------------------------------------
  // PUMP OUTLET RISER
  // --------------------------------------------------

  const riserGeometry =
    new THREE.CylinderGeometry(
      0.27,
      0.27,
      0.92,
      28
    );

  const riser =
    new THREE.Mesh(
      riserGeometry,
      outletMaterial
    );

  riser.position.set(
    0.68,
    0.82,
    0
  );

  riser.castShadow =
    true;

  pumpGroup.add(
    riser
  );

  // --------------------------------------------------
  // MAIN PIPE CONNECTION
  // --------------------------------------------------

  const connectorGeometry =
    new THREE.CylinderGeometry(
      0.30,
      0.30,
      0.52,
      28
    );

  const connector =
    new THREE.Mesh(
      connectorGeometry,
      outletMaterial
    );

  connector.position.set(
    0.68,
    1.54,
    0
  );

  connector.castShadow =
    true;

  pumpGroup.add(
    connector
  );

  // --------------------------------------------------
  // PUMP STATUS LIGHT
  // --------------------------------------------------

  const statusGeometry =
    new THREE.SphereGeometry(
      0.14,
      20,
      20
    );

  const statusMaterial =
    new THREE.MeshBasicMaterial({
      color:
        COLORS.normal,
    });

  const statusLight =
    new THREE.Mesh(
      statusGeometry,
      statusMaterial
    );

  statusLight.position.set(
    0.15,
    0.63,
    -0.62
  );

  pumpGroup.add(
    statusLight
  );

  // --------------------------------------------------
  // SMALL CONTROL BOX
  // --------------------------------------------------

  const controlGeometry =
    new THREE.BoxGeometry(
      0.72,
      0.36,
      0.18
    );

  const controlMaterial =
    new THREE.MeshStandardMaterial({
      color:
        0x233b32,

      roughness:
        0.38,

      metalness:
        0.25,
    });

  const controlBox =
    new THREE.Mesh(
      controlGeometry,
      controlMaterial
    );

  controlBox.position.set(
    -0.10,
    0.38,
    -0.62
  );

  pumpGroup.add(
    controlBox
  );

  scene.add(
    pumpGroup
  );
}

// ======================================================
// PIPE SUPPORTS
// ======================================================

function createPipeSupports() {
  const positions = [
    -5.5,
    0,
    5.5,
  ];

  positions.forEach(
    (x) => {
      const verticalGeometry =
        new THREE.BoxGeometry(
          0.22,
          2.0,
          0.22
        );

      const material =
        new THREE.MeshStandardMaterial({
          color:
            0xd2dfd9,

          roughness:
            0.72,
        });

      const vertical =
        new THREE.Mesh(
          verticalGeometry,
          material
        );

      vertical.position.set(
        x,
        -0.20,
        0
      );

      vertical.castShadow =
        true;

      scene.add(
        vertical
      );

      const topGeometry =
        new THREE.BoxGeometry(
          0.95,
          0.20,
          0.70
        );

      const top =
        new THREE.Mesh(
          topGeometry,
          material
        );

      top.position.set(
        x,
        0.72,
        0
      );

      top.castShadow =
        true;

      scene.add(
        top
      );
    }
  );
}

// ======================================================
// SENSOR
// ======================================================

function createSensor(
  x,
  color,
  name,
  type
) {
  const group =
    new THREE.Group();

  group.position.set(
    x,
    PIPE_Y + 0.82,
    0
  );

  // --------------------------------------------------
  // SENSOR BODY
  // --------------------------------------------------

  const bodyGeometry =
    new THREE.BoxGeometry(
      1.05,
      0.60,
      0.72
    );

  const bodyMaterial =
    new THREE.MeshStandardMaterial({
      color:
        color,

      roughness:
        0.30,

      metalness:
        0.12,
    });

  const body =
    new THREE.Mesh(
      bodyGeometry,
      bodyMaterial
    );

  body.castShadow =
    true;

  group.add(
    body
  );

  // --------------------------------------------------
  // LOWER CONNECTOR
  // --------------------------------------------------

  const lowerGeometry =
    new THREE.BoxGeometry(
      0.72,
      0.17,
      0.52
    );

  const lowerMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.pipeDark,

      roughness:
        0.30,

      metalness:
        0.40,
    });

  const lower =
    new THREE.Mesh(
      lowerGeometry,
      lowerMaterial
    );

  lower.position.y =
    -0.38;

  lower.castShadow =
    true;

  group.add(
    lower
  );

  // --------------------------------------------------
  // STATUS LED
  // --------------------------------------------------

  const ledGeometry =
    new THREE.SphereGeometry(
      0.11,
      20,
      20
    );

  const ledMaterial =
    new THREE.MeshBasicMaterial({
      color:
        COLORS.normal,
    });

  const led =
    new THREE.Mesh(
      ledGeometry,
      ledMaterial
    );

  led.position.set(
    0.27,
    0.38,
    -0.30
  );

  group.add(
    led
  );

  // --------------------------------------------------
  // DATA
  // --------------------------------------------------

  group.userData.sensorName =
    name;

  group.userData.sensorType =
    type;

  group.userData.baseColor =
    color;

  group.userData.body =
    body;

  group.userData.led =
    led;

  sensorObjects.push(
    group
  );

  scene.add(
    group
  );

  return group;
}

// ======================================================
// FLOW SENSORS
// ======================================================

function createFlowSensors() {
  createSensor(
    -7.1,
    COLORS.sensorBlue,
    'YF-S201',
    'FLOW'
  );

  createSensor(
    7.1,
    COLORS.sensorBlue,
    'ZJ-S201',
    'FLOW'
  );
}

// ======================================================
// VIBRATION SENSORS
// ======================================================

function createVibrationSensors() {
  createSensor(
    -3.1,
    COLORS.sensorGreen,
    'Vibration Sensor 1',
    'VIBRATION'
  );

  createSensor(
    3.1,
    COLORS.sensorGreen,
    'Vibration Sensor 2',
    'VIBRATION'
  );
}

// ======================================================
// LEAK ZONES
// ======================================================

function createLeakZones() {
  ZONE_POSITIONS.forEach(
    (x, index) => {
      createLeakZone(
        index + 1,
        x
      );
    }
  );
}

// ======================================================
// LEAK ZONE
// ======================================================

function createLeakZone(
  zoneNumber,
  x
) {
  const group =
    new THREE.Group();

  group.position.set(
    x,
    PIPE_Y,
    0
  );

  // --------------------------------------------------
  // OUTLET NECK
  // --------------------------------------------------

  const neckGeometry =
    new THREE.CylinderGeometry(
      0.30,
      0.30,
      0.50,
      32
    );

  const pipeMaterial =
    new THREE.MeshPhysicalMaterial({
      color:
        COLORS.pipe,

      roughness:
        0.28,

      metalness:
        0.04,

      clearcoat:
        0.30,
    });

  const neck =
    new THREE.Mesh(
      neckGeometry,
      pipeMaterial
    );

  neck.position.y =
    -0.25;

  neck.castShadow =
    true;

  group.add(
    neck
  );

  // --------------------------------------------------
  // VALVE BODY
  // --------------------------------------------------

  const valveGeometry =
    new THREE.CylinderGeometry(
      0.38,
      0.38,
      0.35,
      32
    );

  const valveMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.pipeDark,

      roughness:
        0.28,

      metalness:
        0.55,
    });

  const valve =
    new THREE.Mesh(
      valveGeometry,
      valveMaterial
    );

  valve.position.y =
    -0.57;

  valve.castShadow =
    true;

  group.add(
    valve
  );

  // --------------------------------------------------
  // COLLAR
  // --------------------------------------------------

  const collarGeometry =
    new THREE.CylinderGeometry(
      0.45,
      0.45,
      0.12,
      32
    );

  const collar =
    new THREE.Mesh(
      collarGeometry,
      valveMaterial
    );

  collar.position.y =
    -0.42;

  collar.castShadow =
    true;

  group.add(
    collar
  );

  // --------------------------------------------------
  // RED VALVE HANDLE
  // --------------------------------------------------

  const handleGeometry =
    new THREE.BoxGeometry(
      0.95,
      0.11,
      0.13
    );

  const handleMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.warning,

      roughness:
        0.32,

      metalness:
        0.40,
    });

  const handle =
    new THREE.Mesh(
      handleGeometry,
      handleMaterial
    );

  handle.position.set(
    0.35,
    -0.55,
    -0.03
  );

  handle.castShadow =
    true;

  group.add(
    handle
  );

  // --------------------------------------------------
  // DOWNWARD NOZZLE
  // --------------------------------------------------

  const nozzleGeometry =
    new THREE.CylinderGeometry(
      0.24,
      0.24,
      0.85,
      28
    );

  const nozzle =
    new THREE.Mesh(
      nozzleGeometry,
      pipeMaterial
    );

  nozzle.position.y =
    -1.27;

  nozzle.castShadow =
    true;

  group.add(
    nozzle
  );

  // --------------------------------------------------
  // OUTLET TIP
  // --------------------------------------------------

  const tipGeometry =
    new THREE.CylinderGeometry(
      0.29,
      0.29,
      0.16,
      28
    );

  const tipMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.pipeDark,

      roughness:
        0.32,

      metalness:
        0.38,
    });

  const tip =
    new THREE.Mesh(
      tipGeometry,
      tipMaterial
    );

  tip.position.y =
    -1.72;

  tip.castShadow =
    true;

  group.add(
    tip
  );

  // --------------------------------------------------
  // ZONE RING
  // --------------------------------------------------

  const ringGeometry =
    new THREE.TorusGeometry(
      0.58,
      0.055,
      12,
      48
    );

  const ringMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.normal,

      emissive:
        COLORS.normal,

      emissiveIntensity:
        0.28,

      roughness:
        0.30,

      metalness:
        0.15,
    });

  const ring =
    new THREE.Mesh(
      ringGeometry,
      ringMaterial
    );

  ring.rotation.x =
    Math.PI / 2;

  ring.position.y =
    -1.82;

  group.add(
    ring
  );

  // --------------------------------------------------
  // LEAK CENTER
  // --------------------------------------------------

  const centerGeometry =
    new THREE.SphereGeometry(
      0.09,
      18,
      18
    );

  const centerMaterial =
    new THREE.MeshStandardMaterial({
      color:
        COLORS.normal,

      emissive:
        COLORS.normal,

      emissiveIntensity:
        0.4,
    });

  const center =
    new THREE.Mesh(
      centerGeometry,
      centerMaterial
    );

  center.position.y =
    -1.82;

  group.add(
    center
  );

  // --------------------------------------------------
  // DATA
  // --------------------------------------------------

  group.userData.zone =
    zoneNumber;

  group.userData.ring =
    ring;

  group.userData.center =
    center;

  group.userData.valve =
    valve;

  group.userData.handle =
    handle;

  zoneObjects.push(
    group
  );

  scene.add(
    group
  );
}

// ======================================================
// WATER FLOW
// ======================================================

function createWaterFlow() {
  // --------------------------------------------------
  // WATER CORE
  // --------------------------------------------------

  const waterCoreGeometry =
    new THREE.CylinderGeometry(
      0.46,
      0.46,
      17.25,
      48
    );

  const waterCoreMaterial =
    new THREE.MeshPhysicalMaterial({
      color:
        COLORS.water,

      transparent:
        true,

      opacity:
        0.24,

      roughness:
        0.05,

      metalness:
        0,

      transmission:
        0.05,

      depthWrite:
        false,
    });

  const waterCore =
    new THREE.Mesh(
      waterCoreGeometry,
      waterCoreMaterial
    );

  waterCore.rotation.z =
    Math.PI / 2;

  waterCore.position.set(
    0,
    PIPE_Y,
    0
  );

  waterCore.renderOrder =
    1;

  scene.add(
    waterCore
  );

  // --------------------------------------------------
  // MOVING WATER PARTICLES
  // --------------------------------------------------

  const geometry =
    new THREE.SphereGeometry(
      0.105,
      14,
      14
    );

  for (
    let i = 0;
    i < 140;
    i++
  ) {
    const material =
      new THREE.MeshBasicMaterial({
        color:
          i % 2 === 0
            ? COLORS.water
            : COLORS.waterLight,

        transparent:
          true,

        opacity:
          0.95,

        depthWrite:
          false,
      });

    const particle =
      new THREE.Mesh(
        geometry,
        material
      );

    particle.position.set(
      -8.5 +
        Math.random() *
          17,

      PIPE_Y +
        (Math.random() - 0.5) *
          0.62,

      -0.50 +
        (Math.random() - 0.5) *
          0.18
    );

    particle.userData.speed =
      0.025 +
      Math.random() *
        0.035;

    particle.userData.offset =
      Math.random() *
      Math.PI *
      2;

    particle.userData.depthOffset =
      Math.random() *
      Math.PI *
      2;

    particle.renderOrder =
      2;

    waterParticles.push(
      particle
    );

    scene.add(
      particle
    );
  }
}

// ======================================================
// LEAK PARTICLES
// ======================================================

function createLeakParticles() {
  const geometry =
    new THREE.SphereGeometry(
      0.075,
      10,
      10
    );

  for (
    let i = 0;
    i < 60;
    i++
  ) {
    const material =
      new THREE.MeshBasicMaterial({
        color:
          COLORS.warning,

        transparent:
          true,

        opacity:
          0,
      });

    const particle =
      new THREE.Mesh(
        geometry,
        material
      );

    particle.visible =
      false;

    particle.userData.velocity =
      new THREE.Vector3(
        (Math.random() - 0.5) *
          0.055,

        -0.025 -
          Math.random() *
            0.055,

        (Math.random() - 0.5) *
          0.055
      );

    particle.userData.life =
      Math.random();

    leakParticles.push(
      particle
    );

    scene.add(
      particle
    );
  }
}

// ======================================================
// UPDATE WATER
// ======================================================

function updateWater() {
  const time =
    performance.now();

  waterParticles.forEach(
    (particle) => {
      // LEFT -> RIGHT

      particle.position.x +=
        particle.userData.speed;

      if (
        particle.position.x >
        8.5
      ) {
        particle.position.x =
          -8.5;
      }

      particle.position.y =
        PIPE_Y +
        Math.sin(
          time *
            0.0025 +
          particle.userData.offset
        ) *
          0.22;

      particle.position.z =
        -0.50 +
        Math.sin(
          time *
            0.0018 +
          particle.userData.depthOffset
        ) *
          0.10;
    }
  );
}

// ======================================================
// UPDATE LEAK PARTICLES
// ======================================================

function updateLeakParticles() {
  if (
    !currentLeakZone
  ) {
    leakParticles.forEach(
      (particle) => {
        particle.visible =
          false;
      }
    );

    return;
  }

  const zone =
    zoneObjects.find(
      (item) =>
        item.userData.zone ===
        currentLeakZone
    );

  if (!zone) {
    return;
  }

  const worldPosition =
    new THREE.Vector3();

  zone.userData.center.getWorldPosition(
    worldPosition
  );

  leakParticles.forEach(
    (particle) => {
      particle.visible =
        true;

      if (
        particle.userData.life >=
        1
      ) {
        particle.userData.life =
          0;

        particle.position.copy(
          worldPosition
        );

        particle.position.y -=
          0.04;
      }

      particle.position.add(
        particle.userData.velocity
      );

      particle.userData.life +=
        0.018;

      particle.material.opacity =
        Math.max(
          0,
          1 -
            particle.userData.life
        );

      if (
        particle.userData.life >=
        1
      ) {
        particle.visible =
          false;
      }
    }
  );
}

// ======================================================
// ZONE VISUALS
// ======================================================

function updateZoneVisuals() {
  const time =
    performance.now();

  zoneObjects.forEach(
    (zone) => {
      const ring =
        zone.userData.ring;

      const center =
        zone.userData.center;

      const number =
        zone.userData.zone;

      const isLeak =
        number ===
        currentLeakZone;

      const isSelected =
        number ===
        selectedZone;

      if (isLeak) {
        const pulse =
          Math.sin(
            time * 0.008
          );

        ring.material.color.setHex(
          COLORS.warning
        );

        ring.material.emissive.setHex(
          COLORS.warning
        );

        ring.material.emissiveIntensity =
          1.5 +
          pulse * 0.45;

        ring.scale.setScalar(
          1.15 +
          pulse * 0.10
        );

        center.material.color.setHex(
          COLORS.warning
        );

        center.material.emissive.setHex(
          COLORS.warning
        );

        center.material.emissiveIntensity =
          1.3;

        center.scale.setScalar(
          1.0 +
          pulse * 0.18
        );
      } else if (
        isSelected
      ) {
        ring.material.color.setHex(
          COLORS.selected
        );

        ring.material.emissive.setHex(
          COLORS.selected
        );

        ring.material.emissiveIntensity =
          0.9;

        ring.scale.setScalar(
          1.10
        );

        center.material.color.setHex(
          COLORS.selected
        );

        center.material.emissive.setHex(
          COLORS.selected
        );

        center.scale.setScalar(
          1.08
        );
      } else {
        ring.material.color.setHex(
          COLORS.normal
        );

        ring.material.emissive.setHex(
          COLORS.normal
        );

        ring.material.emissiveIntensity =
          0.28;

        ring.scale.setScalar(
          1
        );

        center.material.color.setHex(
          COLORS.normal
        );

        center.material.emissive.setHex(
          COLORS.normal
        );

        center.scale.setScalar(
          1
        );
      }
    }
  );
}

// ======================================================
// SENSOR VISUALS
// ======================================================

function updateSensorVisuals() {
  const vibration1 =
    currentSensorState.vibration1;

  const vibration2 =
    currentSensorState.vibration2;

  sensorObjects.forEach(
    (sensor) => {
      const type =
        sensor.userData.sensorType;

      const name =
        sensor.userData.sensorName;

      const led =
        sensor.userData.led;

      const body =
        sensor.userData.body;

      if (
        type ===
        'VIBRATION'
      ) {
        const vibration =
          name ===
          'Vibration Sensor 1'
            ? vibration1
            : vibration2;

        if (
          vibration >=
          2.0
        ) {
          body.material.color.setHex(
            COLORS.warning
          );

          led.material.color.setHex(
            COLORS.warning
          );
        } else {
          body.material.color.setHex(
            sensor.userData.baseColor
          );

          led.material.color.setHex(
            COLORS.normal
          );
        }
      } else {
        led.material.color.setHex(
          systemLeakDetected
            ? COLORS.warning
            : COLORS.normal
        );
      }
    }
  );
}

// ======================================================
// ANIMATION LOOP
// ======================================================

function animate() {
  animationFrameId =
    requestAnimationFrame(
      animate
    );

  updateWater();

  updateLeakParticles();

  updateZoneVisuals();

  updateSensorVisuals();

  if (controls) {
    controls.update();
  }

  if (renderer) {
    renderer.render(
      scene,
      camera
    );
  }
}

// ======================================================
// RESIZE
// ======================================================

function resize() {
  if (
    !container ||
    !renderer ||
    !camera
  ) {
    return;
  }

  const width =
    container.clientWidth;

  const height =
    container.clientHeight;

  if (
    width <= 0 ||
    height <= 0
  ) {
    return;
  }

  camera.aspect =
    width / height;

  camera.updateProjectionMatrix();

  renderer.setSize(
    width,
    height,
    false
  );
}

// ======================================================
// SELECT ZONE
// ======================================================

function selectZone(
  zoneNumber
) {
  const number =
    Number(
      zoneNumber
    );

  if (
    number < 1 ||
    number > 3
  ) {
    return;
  }

  selectedZone =
    number;

  updateZoneVisuals();
}

// ======================================================
// SET LEAK ZONE
// ======================================================

function setLeakZone(
  zoneNumber
) {
  const number =
    Number(
      zoneNumber
    );

  if (
    number < 1 ||
    number > 3
  ) {
    clearLeak();

    return;
  }

  systemLeakDetected =
    true;

  currentLeakZone =
    number;

  selectedZone =
    number;

  updateZoneVisuals();

  updateSensorVisuals();
}

// ======================================================
// CLEAR LEAK
// ======================================================

function clearLeak() {
  systemLeakDetected =
    false;

  currentLeakZone =
    null;

  selectedZone =
    null;

  updateZoneVisuals();

  updateSensorVisuals();
}

// ======================================================
// UPDATE SENSOR STATE
// ======================================================

function updateSensorState(
  yfFlowRate,
  zjFlowRate,
  vibration1,
  vibration2,
  leakDetected,
  leakZone
) {
  currentSensorState = {
    yfFlowRate:
      Number(
        yfFlowRate
      ) || 0,

    zjFlowRate:
      Number(
        zjFlowRate
      ) || 0,

    vibration1:
      Number(
        vibration1
      ) || 0,

    vibration2:
      Number(
        vibration2
      ) || 0,
  };

  systemLeakDetected =
    Boolean(
      leakDetected
    );

  if (
    systemLeakDetected &&
    leakZone
  ) {
    currentLeakZone =
      Number(
        String(
          leakZone
        ).replace(
          /[^0-9]/g,
          ''
        )
      );

    if (
      currentLeakZone >=
        1 &&
      currentLeakZone <=
        3
    ) {
      selectedZone =
        currentLeakZone;
    }
  } else if (
    !systemLeakDetected
  ) {
    currentLeakZone =
      null;

    selectedZone =
      null;
  }

  updateZoneVisuals();

  updateSensorVisuals();
}

// ======================================================
// GET CURRENT STATE
// ======================================================

function getState() {
  return {
    leakDetected:
      systemLeakDetected,

    leakZone:
      currentLeakZone,

    yfFlowRate:
      currentSensorState
        .yfFlowRate,

    zjFlowRate:
      currentSensorState
        .zjFlowRate,

    vibration1:
      currentSensorState
        .vibration1,

    vibration2:
      currentSensorState
        .vibration2,
  };
}

// ======================================================
// FLUTTER API
// ======================================================

window.pipeSense3D = {
  selectZone,
  setLeakZone,
  clearLeak,
  updateSensorState,
  getState,
};

// ======================================================
// START
// ======================================================

createScene();