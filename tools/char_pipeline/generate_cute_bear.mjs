import fs from 'node:fs';
import path from 'node:path';

// Polyfill FileReader for GLTFExporter in Node
globalThis.FileReader = class FileReader {
  readAsArrayBuffer(blob) {
    blob.arrayBuffer().then((buf) => {
      this.result = buf;
      this.onloadend?.();
    });
  }
};

import * as THREE from '../../app/stage3d/node_modules/three/build/three.module.js';
import { GLTFExporter } from '../../app/stage3d/node_modules/three/examples/jsm/exporters/GLTFExporter.js';

const repoRoot = path.resolve(import.meta.dirname, '..', '..');
const modelsDir = path.join(repoRoot, 'app', 'stage3d', 'public', 'models');
const appModelsDir = path.join(repoRoot, 'app', 'assets', 'stage3d', 'models');

function eulerToQuat(x, y, z) {
  const e = new THREE.Euler(x, y, z, 'XYZ');
  const q = new THREE.Quaternion().setFromEuler(e);
  return [q.x, q.y, q.z, q.w];
}

// Materials
const furMat = new THREE.MeshStandardMaterial({
  name: 'BearFur',
  color: 0xa0673a, // Warm teddy brown
  roughness: 0.82,
  metalness: 0.05,
});

const muzzleMat = new THREE.MeshStandardMaterial({
  name: 'BearMuzzle',
  color: 0xfae5cb, // Creamy vanilla for snout, belly, inner ears, foot soles
  roughness: 0.85,
  metalness: 0.02,
});

const detailsMat = new THREE.MeshStandardMaterial({
  name: 'BearDetails',
  color: 0x221713, // Deep glossy espresso for nose and eyes
  roughness: 0.25,
  metalness: 0.1,
});

function createBearScene(tier) {
  const segMult = tier === 'high' ? 1.0 : tier === 'medium' ? 0.75 : 0.55;
  const s = (val) => Math.max(6, Math.round(val * segMult));

  // Skeleton
  const rootBone = new THREE.Bone();
  rootBone.name = 'Root';
  rootBone.position.set(0, 0, 0);

  const hipsBone = new THREE.Bone();
  hipsBone.name = 'Hips';
  hipsBone.position.set(0, 0.42, 0);
  rootBone.add(hipsBone);

  const spineBone = new THREE.Bone();
  spineBone.name = 'Spine';
  spineBone.position.set(0, 0.32, 0); // world y = 0.74
  hipsBone.add(spineBone);

  const neckBone = new THREE.Bone();
  neckBone.name = 'Neck';
  neckBone.position.set(0, 0.28, 0); // world y = 1.02
  spineBone.add(neckBone);

  const headBone = new THREE.Bone();
  headBone.name = 'Head';
  headBone.position.set(0, 0.22, 0); // world y = 1.24
  neckBone.add(headBone);

  const leftArmBone = new THREE.Bone();
  leftArmBone.name = 'LeftArm';
  leftArmBone.position.set(-0.36, 0.16, 0); // relative to spine
  spineBone.add(leftArmBone);

  const rightArmBone = new THREE.Bone();
  rightArmBone.name = 'RightArm';
  rightArmBone.position.set(0.36, 0.16, 0);
  spineBone.add(rightArmBone);

  const leftLegBone = new THREE.Bone();
  leftLegBone.name = 'LeftLeg';
  leftLegBone.position.set(-0.20, -0.05, 0); // relative to hips
  hipsBone.add(leftLegBone);

  const rightLegBone = new THREE.Bone();
  rightLegBone.name = 'RightLeg';
  rightLegBone.position.set(0.20, -0.05, 0);
  hipsBone.add(rightLegBone);

  const bones = [
    rootBone,     // 0
    hipsBone,     // 1
    spineBone,    // 2
    neckBone,     // 3
    headBone,     // 4
    leftArmBone,  // 5
    rightArmBone, // 6
    leftLegBone,  // 7
    rightLegBone, // 8
  ];

  // Helper to create a skinned submesh attached to a specific bone
  function createSkinnedPart(geometry, material, boneIndex, worldOffset = [0, 0, 0], scale = [1, 1, 1], rot = [0, 0, 0]) {
    geometry = geometry.clone();
    geometry.scale(scale[0], scale[1], scale[2]);
    geometry.rotateX(rot[0]);
    geometry.rotateY(rot[1]);
    geometry.rotateZ(rot[2]);
    geometry.translate(worldOffset[0], worldOffset[1], worldOffset[2]);

    const pos = geometry.attributes.position;
    const vertexCount = pos.count;
    const skinIndices = new Float32Array(vertexCount * 4);
    const skinWeights = new Float32Array(vertexCount * 4);

    for (let i = 0; i < vertexCount; i++) {
      skinIndices[i * 4] = boneIndex;
      skinIndices[i * 4 + 1] = 0;
      skinIndices[i * 4 + 2] = 0;
      skinIndices[i * 4 + 3] = 0;

      skinWeights[i * 4] = 1.0;
      skinWeights[i * 4 + 1] = 0.0;
      skinWeights[i * 4 + 2] = 0.0;
      skinWeights[i * 4 + 3] = 0.0;
    }

    geometry.setAttribute('skinIndex', new THREE.BufferAttribute(skinIndices, 4));
    geometry.setAttribute('skinWeight', new THREE.BufferAttribute(skinWeights, 4));

    const mesh = new THREE.SkinnedMesh(geometry, material);
    mesh.name = 'BearPart';
    return mesh;
  }

  const parts = [];

  // --- HEAD (bone 4, world y = 1.24) ---
  // Main Head: round cute teddy head
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.38, s(20), s(16)),
    furMat, 4, [0, 1.24, 0], [1.08, 0.98, 1.0]
  ));

  // Snout/Muzzle: creamy protruding snout
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.18, s(16), s(12)),
    muzzleMat, 4, [0, 1.18, 0.32], [1.15, 0.78, 1.1]
  ));

  // Cute Button Nose
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.055, s(12), s(10)),
    detailsMat, 4, [0, 1.23, 0.45], [1.2, 0.8, 1.0]
  ));

  // Big glossy dark eyes
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.048, s(12), s(10)),
    detailsMat, 4, [-0.15, 1.28, 0.34]
  ));
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.048, s(12), s(10)),
    detailsMat, 4, [0.15, 1.28, 0.34]
  ));

  // Left & Right Outer Ears
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.13, s(14), s(12)),
    furMat, 4, [-0.28, 1.56, 0.0], [1.0, 1.0, 0.65], [0, 0, 0.2]
  ));
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.13, s(14), s(12)),
    furMat, 4, [0.28, 1.56, 0.0], [1.0, 1.0, 0.65], [0, 0, -0.2]
  ));

  // Left & Right Inner Ear Cups (Creamy)
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.085, s(12), s(10)),
    muzzleMat, 4, [-0.28, 1.56, 0.035], [0.9, 0.9, 0.4], [0, 0, 0.2]
  ));
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.085, s(12), s(10)),
    muzzleMat, 4, [0.28, 1.56, 0.035], [0.9, 0.9, 0.4], [0, 0, -0.2]
  ));

  // --- TORSO (bone 2: Spine at y = 0.74, bone 1: Hips at y = 0.42) ---
  // Upper Chest (Spine)
  parts.push(createSkinnedPart(
    new THREE.CylinderGeometry(0.26, 0.36, 0.38, s(18)),
    furMat, 2, [0, 0.88, 0]
  ));

  // Chubby Lower Belly (Hips)
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.40, s(18), s(14)),
    furMat, 1, [0, 0.58, 0], [1.0, 0.92, 0.96]
  ));

  // Round Cream Tummy Patch (Hips)
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.26, s(16), s(12)),
    muzzleMat, 1, [0, 0.62, 0.28], [0.9, 1.15, 0.35]
  ));

  // Little cute tail (Hips)
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.08, s(10), s(8)),
    furMat, 1, [0, 0.44, -0.36]
  ));

  // --- ARMS & PAWS (bone 5: LeftArm, bone 6: RightArm) ---
  // Left Arm
  parts.push(createSkinnedPart(
    new THREE.CapsuleGeometry(0.09, 0.32, s(6), s(12)),
    furMat, 5, [-0.36, 0.78, 0.04], [1, 1, 1], [0.2, 0, -0.2]
  ));
  // Left Paw pad
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.095, s(10), s(8)),
    muzzleMat, 5, [-0.40, 0.62, 0.12]
  ));

  // Right Arm
  parts.push(createSkinnedPart(
    new THREE.CapsuleGeometry(0.09, 0.32, s(6), s(12)),
    furMat, 6, [0.36, 0.78, 0.04], [1, 1, 1], [0.2, 0, 0.2]
  ));
  // Right Paw pad
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.095, s(10), s(8)),
    muzzleMat, 6, [0.40, 0.62, 0.12]
  ));

  // --- LEGS & FEET (bone 7: LeftLeg, bone 8: RightLeg) ---
  // Left Leg
  parts.push(createSkinnedPart(
    new THREE.CapsuleGeometry(0.11, 0.28, s(6), s(12)),
    furMat, 7, [-0.20, 0.26, 0.02]
  ));
  // Left Foot
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.12, s(12), s(8)),
    muzzleMat, 7, [-0.20, 0.10, 0.08], [0.95, 0.65, 1.25]
  ));

  // Right Leg
  parts.push(createSkinnedPart(
    new THREE.CapsuleGeometry(0.11, 0.28, s(6), s(12)),
    furMat, 8, [0.20, 0.26, 0.02]
  ));
  // Right Foot
  parts.push(createSkinnedPart(
    new THREE.SphereGeometry(0.12, s(12), s(8)),
    muzzleMat, 8, [0.20, 0.10, 0.08], [0.95, 0.65, 1.25]
  ));

  // Create skeleton & bind to all skinned meshes
  const skeleton = new THREE.Skeleton(bones);
  for (const part of parts) {
    part.bind(skeleton);
  }

  // Animation Clips
  const clips = [
    // 1. idle: gentle breathing rhythm
    new THREE.AnimationClip('idle', 2.0, [
      new THREE.QuaternionKeyframeTrack('Spine.quaternion', [0, 1.0, 2.0], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(-0.06, 0, 0),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.VectorKeyframeTrack('Hips.position', [0, 1.0, 2.0], [
        0, 0.42, 0,
        0, 0.44, 0,
        0, 0.42, 0,
      ]),
      new THREE.QuaternionKeyframeTrack('Head.quaternion', [0, 1.0, 2.0], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0.04, 0, 0.03),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.QuaternionKeyframeTrack('LeftArm.quaternion', [0, 1.0, 2.0], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0.05, 0, 0.04),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.QuaternionKeyframeTrack('RightArm.quaternion', [0, 1.0, 2.0], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0.05, 0, -0.04),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),

    // 2. think: paw to snout, curious head tilt
    new THREE.AnimationClip('think', 1.5, [
      new THREE.QuaternionKeyframeTrack('Head.quaternion', [0, 0.4, 1.1, 1.5], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(-0.1, 0.15, 0.22),
        ...eulerToQuat(-0.1, 0.15, 0.22),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.QuaternionKeyframeTrack('RightArm.quaternion', [0, 0.4, 1.1, 1.5], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(1.4, 0.3, -0.4),
        ...eulerToQuat(1.4, 0.3, -0.4),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),

    // 3. encourage: friendly paw wave and nod
    new THREE.AnimationClip('encourage', 1.2, [
      new THREE.QuaternionKeyframeTrack('Head.quaternion', [0, 0.3, 0.6, 0.9, 1.2], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0.12, 0, 0),
        ...eulerToQuat(-0.06, 0, 0),
        ...eulerToQuat(0.12, 0, 0),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.QuaternionKeyframeTrack('RightArm.quaternion', [0, 0.3, 0.6, 0.9, 1.2], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(1.2, 0, -0.4),
        ...eulerToQuat(1.2, 0, 0.1),
        ...eulerToQuat(1.2, 0, -0.4),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),

    // 4. happy: little joyful bounce, arms up
    new THREE.AnimationClip('happy', 1.0, [
      new THREE.VectorKeyframeTrack('Hips.position', [0, 0.25, 0.5, 0.75, 1.0], [
        0, 0.42, 0,
        0, 0.52, 0,
        0, 0.42, 0,
        0, 0.50, 0,
        0, 0.42, 0,
      ]),
      new THREE.QuaternionKeyframeTrack('LeftArm.quaternion', [0, 0.3, 0.7, 1.0], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(1.3, 0, 0.5),
        ...eulerToQuat(1.3, 0, 0.5),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.QuaternionKeyframeTrack('RightArm.quaternion', [0, 0.3, 0.7, 1.0], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(1.3, 0, -0.5),
        ...eulerToQuat(1.3, 0, -0.5),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),

    // 5. celebrate: big jump, triumphant celebration!
    new THREE.AnimationClip('celebrate', 1.4, [
      new THREE.VectorKeyframeTrack('Hips.position', [0, 0.3, 0.6, 0.9, 1.2, 1.4], [
        0, 0.42, 0,
        0, 0.58, 0,
        0, 0.42, 0,
        0, 0.58, 0,
        0, 0.42, 0,
        0, 0.42, 0,
      ]),
      new THREE.QuaternionKeyframeTrack('LeftArm.quaternion', [0, 0.3, 0.6, 0.9, 1.2, 1.4], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(2.0, 0.2, 0.6),
        ...eulerToQuat(1.6, 0.2, 0.3),
        ...eulerToQuat(2.0, 0.2, 0.6),
        ...eulerToQuat(1.6, 0.2, 0.3),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.QuaternionKeyframeTrack('RightArm.quaternion', [0, 0.3, 0.6, 0.9, 1.2, 1.4], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(2.0, -0.2, -0.6),
        ...eulerToQuat(1.6, -0.2, -0.3),
        ...eulerToQuat(2.0, -0.2, -0.6),
        ...eulerToQuat(1.6, -0.2, -0.3),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),

    // 6. confused: quizzical head tilt, questioning arms
    new THREE.AnimationClip('confused', 1.2, [
      new THREE.QuaternionKeyframeTrack('Head.quaternion', [0, 0.4, 0.8, 1.2], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0, 0, 0.3),
        ...eulerToQuat(0, 0, 0.3),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.QuaternionKeyframeTrack('LeftArm.quaternion', [0, 0.4, 0.8, 1.2], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0.6, 0, 0.5),
        ...eulerToQuat(0.6, 0, 0.5),
        ...eulerToQuat(0, 0, 0),
      ]),
      new THREE.QuaternionKeyframeTrack('RightArm.quaternion', [0, 0.4, 0.8, 1.2], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0.6, 0, -0.5),
        ...eulerToQuat(0.6, 0, -0.5),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),

    // 7. idle_alt: look around
    new THREE.AnimationClip('idle_alt', 2.0, [
      new THREE.QuaternionKeyframeTrack('Head.quaternion', [0, 0.5, 1.2, 1.7, 2.0], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0, 0.35, 0.05),
        ...eulerToQuat(0, -0.35, -0.05),
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),

    // 8. tap_react: surprised little bounce
    new THREE.AnimationClip('tap_react', 0.8, [
      new THREE.VectorKeyframeTrack('Hips.position', [0, 0.2, 0.4, 0.8], [
        0, 0.42, 0,
        0, 0.50, 0,
        0, 0.40, 0,
        0, 0.42, 0,
      ]),
      new THREE.QuaternionKeyframeTrack('Head.quaternion', [0, 0.2, 0.5, 0.8], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(-0.15, 0, 0),
        ...eulerToQuat(0.1, 0, 0),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),

    // 9. point: point right arm towards basket
    new THREE.AnimationClip('point', 1.0, [
      new THREE.QuaternionKeyframeTrack('RightArm.quaternion', [0, 0.3, 0.7, 1.0], [
        ...eulerToQuat(0, 0, 0),
        ...eulerToQuat(1.3, 0.2, -0.2),
        ...eulerToQuat(1.3, 0.2, -0.2),
        ...eulerToQuat(0, 0, 0),
      ]),
    ]),
  ];

  const rootGroup = new THREE.Group();
  rootGroup.name = 'BearCharacter';
  rootGroup.add(rootBone);
  for (const part of parts) {
    rootGroup.add(part);
  }

  return { rootGroup, clips };
}

async function exportTier(tier) {
  const { rootGroup, clips } = createBearScene(tier);
  const exporter = new GLTFExporter();

  return new Promise((resolve, reject) => {
    exporter.parse(
      rootGroup,
      (glb) => {
        const buf = Buffer.from(glb);
        const out1 = path.join(modelsDir, `bear.${tier}.glb`);
        const out2 = path.join(appModelsDir, `bear.${tier}.glb`);
        fs.writeFileSync(out1, buf);
        fs.writeFileSync(out2, buf);
        console.log(`✓ Exported bear.${tier}.glb (${buf.length} bytes) to public & app`);
        resolve(buf);
      },
      (err) => reject(err),
      {
        binary: true,
        animations: clips,
      }
    );
  });
}

async function main() {
  console.log('=== Generating Adorable Cartoon 3D Bear Models ===');
  for (const tier of ['high', 'medium', 'low']) {
    await exportTier(tier);
  }
  console.log('✅ Generation complete!');
}

main().catch((err) => {
  console.error('Fatal error:', err);
  process.exit(1);
});
