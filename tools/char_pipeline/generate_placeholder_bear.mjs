import fs from 'node:fs';
import path from 'node:path';

function buildGlb() {
  // Let's create a cute low-poly cartoon character
  // Bones:
  // 0: Root (0, 0, 0)
  // 1: Hips (0, 0.6, 0)
  // 2: Spine (0, 0.9, 0)
  // 3: Neck (0, 1.1, 0)
  // 4: Head (0, 1.3, 0)
  // 5: LeftArm (-0.45, 0.95, 0)
  // 6: RightArm (0.45, 0.95, 0)
  // 7: LeftLeg (-0.2, 0.5, 0)
  // 8: RightLeg (0.2, 0.5, 0)

  const bonePositions = [
    [0, 0, 0],       // 0: Root
    [0, 0.6, 0],     // 1: Hips
    [0, 0.9, 0],     // 2: Spine
    [0, 1.1, 0],     // 3: Neck
    [0, 1.3, 0],     // 4: Head
    [-0.4, 0.95, 0], // 5: LeftArm
    [0.4, 0.95, 0],  // 6: RightArm
    [-0.2, 0.45, 0], // 7: LeftLeg
    [0.2, 0.45, 0],  // 8: RightLeg
  ];

  // Helper to create a box mesh
  // returns { positions, normals, uvs, joints, weights, indices }
  function createBox(cx, cy, cz, sx, sy, sz, boneIdx) {
    const hx = sx / 2, hy = sy / 2, hz = sz / 2;
    // 6 faces * 4 vertices = 24 vertices
    const p = [];
    const n = [];
    const u = [];
    const j = [];
    const w = [];
    const ind = [];

    const faces = [
      // Front (Z+)
      { norm: [0, 0, 1], pts: [[-hx, -hy, hz], [hx, -hy, hz], [hx, hy, hz], [-hx, hy, hz]] },
      // Back (Z-)
      { norm: [0, 0, -1], pts: [[hx, -hy, -hz], [-hx, -hy, -hz], [-hx, hy, -hz], [hx, hy, -hz]] },
      // Top (Y+)
      { norm: [0, 1, 0], pts: [[-hx, hy, hz], [hx, hy, hz], [hx, hy, -hz], [-hx, hy, -hz]] },
      // Bottom (Y-)
      { norm: [0, -1, 0], pts: [[-hx, -hy, -hz], [hx, -hy, -hz], [hx, -hy, hz], [-hx, -hy, hz]] },
      // Right (X+)
      { norm: [1, 0, 0], pts: [[hx, -hy, hz], [hx, -hy, -hz], [hx, hy, -hz], [hx, hy, hz]] },
      // Left (X-)
      { norm: [-1, 0, 0], pts: [[-hx, -hy, -hz], [-hx, -hy, hz], [-hx, hy, hz], [-hx, hy, -hz]] },
    ];

    let baseIdx = 0;
    for (const face of faces) {
      for (let k = 0; k < 4; k++) {
        p.push(cx + face.pts[k][0], cy + face.pts[k][1], cz + face.pts[k][2]);
        n.push(face.norm[0], face.norm[1], face.norm[2]);
        u.push(k === 1 || k === 2 ? 1 : 0, k >= 2 ? 1 : 0);
        j.push(boneIdx, 0, 0, 0);
        w.push(1.0, 0.0, 0.0, 0.0);
      }
      ind.push(baseIdx, baseIdx + 1, baseIdx + 2, baseIdx, baseIdx + 2, baseIdx + 3);
      baseIdx += 4;
    }

    return { p, n, u, j, w, ind };
  }

  // Combine body parts
  const parts = [
    // Torso / Belly (attached to Spine bone 2)
    createBox(0, 0.75, 0, 0.5, 0.55, 0.4, 2),
    // Head (attached to Head bone 4)
    createBox(0, 1.25, 0, 0.45, 0.4, 0.4, 4),
    // Snout
    createBox(0, 1.18, 0.22, 0.22, 0.16, 0.18, 4),
    // Left Ear
    createBox(-0.18, 1.48, 0, 0.12, 0.12, 0.08, 4),
    // Right Ear
    createBox(0.18, 1.48, 0, 0.12, 0.12, 0.08, 4),
    // Left Arm (attached to bone 5)
    createBox(-0.35, 0.8, 0, 0.16, 0.35, 0.16, 5),
    // Right Arm (attached to bone 6)
    createBox(0.35, 0.8, 0, 0.16, 0.35, 0.16, 6),
    // Left Leg (attached to bone 7)
    createBox(-0.18, 0.25, 0, 0.18, 0.5, 0.2, 7),
    // Right Leg (attached to bone 8)
    createBox(0.18, 0.25, 0, 0.18, 0.5, 0.2, 8),
  ];

  const allPositions = [];
  const allNormals = [];
  const allUvs = [];
  const allJoints = [];
  const allWeights = [];
  const allIndices = [];

  let vertOffset = 0;
  for (const part of parts) {
    allPositions.push(...part.p);
    allNormals.push(...part.n);
    allUvs.push(...part.u);
    allJoints.push(...part.j);
    allWeights.push(...part.w);
    for (const idx of part.ind) {
      allIndices.push(vertOffset + idx);
    }
    vertOffset += part.p.length / 3;
  }

  // Animation helpers
  // Quaternions: [x, y, z, w]
  // Euler to Quaternion (pitch, yaw, roll around x, y, z in radians)
  function eulerToQuat(rx, ry, rz) {
    const cx = Math.cos(rx / 2), sx = Math.sin(rx / 2);
    const cy = Math.cos(ry / 2), sy = Math.sin(ry / 2);
    const cz = Math.cos(rz / 2), sz = Math.sin(rz / 2);
    return [
      sx * cy * cz - cx * sy * sz,
      cx * sy * cz + sx * cy * sz,
      cx * cy * sz - sx * sy * cz,
      cx * cy * cz + sx * sy * sz,
    ];
  }

  // Animation clips to build:
  // idle, think, encourage, happy, celebrate, confused, idle_alt, tap_react, point
  const clipDefinitions = [
    {
      name: 'idle',
      duration: 2.0,
      tracks: [
        { node: 2, times: [0, 1.0, 2.0], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(0.05, 0, 0), ...eulerToQuat(0, 0, 0)] },
        { node: 4, times: [0, 1.0, 2.0], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(-0.03, 0, 0), ...eulerToQuat(0, 0, 0)] },
      ],
    },
    {
      name: 'think',
      duration: 1.5,
      tracks: [
        { node: 4, times: [0, 0.75, 1.5], values: [...eulerToQuat(0.1, 0.15, 0.1), ...eulerToQuat(0.15, 0.2, 0.12), ...eulerToQuat(0.1, 0.15, 0.1)] },
        { node: 6, times: [0, 0.75, 1.5], values: [...eulerToQuat(0.8, 0, -0.4), ...eulerToQuat(0.9, 0, -0.4), ...eulerToQuat(0.8, 0, -0.4)] },
      ],
    },
    {
      name: 'encourage',
      duration: 1.2,
      tracks: [
        { node: 4, times: [0, 0.3, 0.6, 0.9, 1.2], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(0.15, 0, 0), ...eulerToQuat(0, 0, 0), ...eulerToQuat(0.15, 0, 0), ...eulerToQuat(0, 0, 0)] },
        { node: 5, times: [0, 0.6, 1.2], values: [...eulerToQuat(0.3, 0, 0.4), ...eulerToQuat(0.5, 0, 0.6), ...eulerToQuat(0.3, 0, 0.4)] },
        { node: 6, times: [0, 0.6, 1.2], values: [...eulerToQuat(0.3, 0, -0.4), ...eulerToQuat(0.5, 0, -0.6), ...eulerToQuat(0.3, 0, -0.4)] },
      ],
    },
    {
      name: 'happy',
      duration: 0.8,
      tracks: [
        { node: 1, times: [0, 0.4, 0.8], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(0, 0.2, 0), ...eulerToQuat(0, 0, 0)] },
        { node: 4, times: [0, 0.2, 0.4, 0.6, 0.8], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(0.2, 0, 0), ...eulerToQuat(0, 0, 0), ...eulerToQuat(0.2, 0, 0), ...eulerToQuat(0, 0, 0)] },
        { node: 5, times: [0, 0.4, 0.8], values: [...eulerToQuat(1.0, 0, 0.5), ...eulerToQuat(1.3, 0, 0.7), ...eulerToQuat(1.0, 0, 0.5)] },
        { node: 6, times: [0, 0.4, 0.8], values: [...eulerToQuat(1.0, 0, -0.5), ...eulerToQuat(1.3, 0, -0.7), ...eulerToQuat(1.0, 0, -0.5)] },
      ],
    },
    {
      name: 'celebrate',
      duration: 1.5,
      tracks: [
        { node: 0, times: [0, 0.75, 1.5], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(0, Math.PI, 0), ...eulerToQuat(0, Math.PI * 2, 0)] },
        { node: 5, times: [0, 0.35, 0.75, 1.15, 1.5], values: [...eulerToQuat(1.2, 0, 0.4), ...eulerToQuat(1.5, 0, 0.8), ...eulerToQuat(1.2, 0, 0.4), ...eulerToQuat(1.5, 0, 0.8), ...eulerToQuat(1.2, 0, 0.4)] },
        { node: 6, times: [0, 0.35, 0.75, 1.15, 1.5], values: [...eulerToQuat(1.2, 0, -0.4), ...eulerToQuat(1.5, 0, -0.8), ...eulerToQuat(1.2, 0, -0.4), ...eulerToQuat(1.5, 0, -0.8), ...eulerToQuat(1.2, 0, -0.4)] },
      ],
    },
    {
      name: 'confused',
      duration: 1.4,
      tracks: [
        { node: 4, times: [0, 0.4, 0.9, 1.4], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(0.05, 0, 0.25), ...eulerToQuat(0.05, 0, -0.25), ...eulerToQuat(0, 0, 0)] },
      ],
    },
    {
      name: 'idle_alt',
      duration: 2.0,
      tracks: [
        { node: 4, times: [0, 0.6, 1.4, 2.0], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(0, 0.35, 0), ...eulerToQuat(0, -0.35, 0), ...eulerToQuat(0, 0, 0)] },
      ],
    },
    {
      name: 'tap_react',
      duration: 0.5,
      tracks: [
        { node: 2, times: [0, 0.15, 0.35, 0.5], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(-0.2, 0, 0), ...eulerToQuat(0.1, 0, 0), ...eulerToQuat(0, 0, 0)] },
      ],
    },
    {
      name: 'point',
      duration: 1.0,
      tracks: [
        { node: 6, times: [0, 0.3, 0.8, 1.0], values: [...eulerToQuat(0, 0, 0), ...eulerToQuat(1.2, 0, -0.2), ...eulerToQuat(1.2, 0, -0.2), ...eulerToQuat(0, 0, 0)] },
      ],
    },
  ];

  // Binary buffer packing
  const bufferParts = [];
  let byteOffset = 0;

  function appendBuffer(data, type) {
    let buf;
    if (type === 'float') {
      buf = Buffer.from(new Float32Array(data).buffer);
    } else if (type === 'uint16') {
      buf = Buffer.from(new Uint16Array(data).buffer);
    } else {
      buf = Buffer.from(data);
    }
    // Align to 4 bytes
    const pad = (4 - (buf.length % 4)) % 4;
    if (pad > 0) {
      buf = Buffer.concat([buf, Buffer.alloc(pad)]);
    }
    const offset = byteOffset;
    byteOffset += buf.length;
    bufferParts.push(buf);
    return { byteOffset: offset, byteLength: buf.length };
  }

  const accessors = [];
  const bufferViews = [];

  function addBufferView(data, type, target) {
    const { byteOffset: bOffset, byteLength: bLength } = appendBuffer(data, type);
    const viewIdx = bufferViews.length;
    const viewObj = {
      buffer: 0,
      byteOffset: bOffset,
      byteLength: bLength,
    };
    if (target) {
      viewObj.target = target;
    }
    bufferViews.push(viewObj);
    return viewIdx;
  }

  // 1. Indices
  const indView = addBufferView(allIndices, 'uint16', 34963); // ELEMENT_ARRAY_BUFFER
  accessors.push({
    bufferView: indView,
    byteOffset: 0,
    componentType: 5123, // UNSIGNED_SHORT
    count: allIndices.length,
    type: 'SCALAR',
    max: [Math.max(...allIndices)],
    min: [0],
  });

  // 2. Positions
  const posView = addBufferView(allPositions, 'float', 34962); // ARRAY_BUFFER
  let minP = [Infinity, Infinity, Infinity];
  let maxP = [-Infinity, -Infinity, -Infinity];
  for (let i = 0; i < allPositions.length; i += 3) {
    for (let c = 0; c < 3; c++) {
      if (allPositions[i + c] < minP[c]) minP[c] = allPositions[i + c];
      if (allPositions[i + c] > maxP[c]) maxP[c] = allPositions[i + c];
    }
  }
  accessors.push({
    bufferView: posView,
    byteOffset: 0,
    componentType: 5126, // FLOAT
    count: allPositions.length / 3,
    type: 'VEC3',
    max: maxP,
    min: minP,
  });

  // 3. Normals
  const normView = addBufferView(allNormals, 'float', 34962);
  accessors.push({
    bufferView: normView,
    byteOffset: 0,
    componentType: 5126,
    count: allNormals.length / 3,
    type: 'VEC3',
  });

  // 4. UVs
  const uvView = addBufferView(allUvs, 'float', 34962);
  accessors.push({
    bufferView: uvView,
    byteOffset: 0,
    componentType: 5126,
    count: allUvs.length / 2,
    type: 'VEC2',
  });

  // 5. Joints
  const jointView = addBufferView(allJoints, 'uint16', 34962);
  accessors.push({
    bufferView: jointView,
    byteOffset: 0,
    componentType: 5123,
    count: allJoints.length / 4,
    type: 'VEC4',
  });

  // 6. Weights
  const weightView = addBufferView(allWeights, 'float', 34962);
  accessors.push({
    bufferView: weightView,
    byteOffset: 0,
    componentType: 5126,
    count: allWeights.length / 4,
    type: 'VEC4',
  });

  // 7. Inverse Bind Matrices (9 identity matrices for 9 bones)
  const ibm = [];
  for (let b = 0; b < 9; b++) {
    // Identity 4x4
    ibm.push(
      1, 0, 0, 0,
      0, 1, 0, 0,
      0, 0, 1, 0,
      0, 0, 0, 1
    );
  }
  const ibmView = addBufferView(ibm, 'float');
  accessors.push({
    bufferView: ibmView,
    byteOffset: 0,
    componentType: 5126,
    count: 9,
    type: 'MAT4',
  });

  // Animations buffer packing
  const animations = [];
  for (const clip of clipDefinitions) {
    const samplers = [];
    const channels = [];

    for (const track of clip.tracks) {
      // Time accessor
      const timeView = addBufferView(track.times, 'float');
      const timeAccIdx = accessors.length;
      accessors.push({
        bufferView: timeView,
        byteOffset: 0,
        componentType: 5126,
        count: track.times.length,
        type: 'SCALAR',
        max: [Math.max(...track.times)],
        min: [Math.min(...track.times)],
      });

      // Output (Quat) accessor
      const valView = addBufferView(track.values, 'float');
      const valAccIdx = accessors.length;
      accessors.push({
        bufferView: valView,
        byteOffset: 0,
        componentType: 5126,
        count: track.values.length / 4,
        type: 'VEC4',
      });

      const samplerIdx = samplers.length;
      samplers.push({
        input: timeAccIdx,
        interpolation: 'LINEAR',
        output: valAccIdx,
      });

      channels.push({
        sampler: samplerIdx,
        target: {
          node: track.node,
          path: 'rotation',
        },
      });
    }

    animations.push({
      name: clip.name,
      samplers,
      channels,
    });
  }

  // Nodes hierarchy
  // 0: Root, 1: Hips, 2: Spine, 3: Neck, 4: Head, 5: LeftArm, 6: RightArm, 7: LeftLeg, 8: RightLeg, 9: MeshNode
  const nodes = [
    { name: 'Root', translation: bonePositions[0], children: [1, 9] },
    { name: 'Hips', translation: bonePositions[1], children: [2, 7, 8] },
    { name: 'Spine', translation: [0, 0.3, 0], children: [3, 5, 6] },
    { name: 'Neck', translation: [0, 0.2, 0], children: [4] },
    { name: 'Head', translation: [0, 0.2, 0] },
    { name: 'LeftArm', translation: [-0.4, 0.05, 0] },
    { name: 'RightArm', translation: [0.4, 0.05, 0] },
    { name: 'LeftLeg', translation: [-0.18, -0.15, 0] },
    { name: 'RightLeg', translation: [0.18, -0.15, 0] },
    { name: 'BearMesh', mesh: 0, skin: 0 },
  ];

  const gltf = {
    asset: { version: '2.0', generator: 'NovaCharPipeline' },
    scenes: [{ nodes: [0] }],
    scene: 0,
    nodes,
    materials: [
      {
        name: 'BearMaterial',
        pbrMetallicRoughness: {
          baseColorFactor: [0.65, 0.45, 0.28, 1.0], // Cartoon bear brown
          metallicFactor: 0.0,
          roughnessFactor: 0.8,
        },
      },
    ],
    meshes: [
      {
        name: 'Bear',
        primitives: [
          {
            attributes: {
              POSITION: 1,
              NORMAL: 2,
              TEXCOORD_0: 3,
              JOINTS_0: 4,
              WEIGHTS_0: 5,
            },
            indices: 0,
            material: 0,
          },
        ],
      },
    ],
    skins: [
      {
        name: 'BearRig',
        inverseBindMatrices: 6,
        joints: [0, 1, 2, 3, 4, 5, 6, 7, 8],
      },
    ],
    animations,
    accessors,
    bufferViews,
    buffers: [{ byteLength: byteOffset }],
  };

  const jsonStr = JSON.stringify(gltf);
  let jsonBuf = Buffer.from(jsonStr, 'utf8');
  const jsonPad = (4 - (jsonBuf.length % 4)) % 4;
  if (jsonPad > 0) {
    jsonBuf = Buffer.concat([jsonBuf, Buffer.alloc(jsonPad, 0x20)]);
  }

  const binBuf = Buffer.concat(bufferParts);

  // GLB Header
  const totalLength = 12 + 8 + jsonBuf.length + 8 + binBuf.length;
  const headerBuf = Buffer.alloc(12);
  headerBuf.writeUInt32LE(0x46546c67, 0); // 'glTF'
  headerBuf.writeUInt32LE(2, 4);          // version 2
  headerBuf.writeUInt32LE(totalLength, 8);

  const jsonHeader = Buffer.alloc(8);
  jsonHeader.writeUInt32LE(jsonBuf.length, 0);
  jsonHeader.writeUInt32LE(0x4e4f534a, 4); // 'JSON'

  const binHeader = Buffer.alloc(8);
  binHeader.writeUInt32LE(binBuf.length, 0);
  binHeader.writeUInt32LE(0x004e4942, 4); // 'BIN\0'

  const finalGlb = Buffer.concat([headerBuf, jsonHeader, jsonBuf, binHeader, binBuf]);
  return finalGlb;
}

// Write source.glb to art-src/characters/bear/source.glb
const outDir = path.resolve('..', '..', 'art-src', 'characters', 'bear');
fs.mkdirSync(outDir, { recursive: true });
const glbBuffer = buildGlb();
const outPath = path.join(outDir, 'source.glb');
fs.writeFileSync(outPath, glbBuffer);
console.log(`Generated CC0 rigged bear source model: ${outPath} (${glbBuffer.length} bytes)`);
