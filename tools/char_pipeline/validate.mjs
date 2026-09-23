import fs from 'node:fs';
import path from 'node:path';
import YAML from 'yaml';

const charId = process.argv[2] || 'bear';
const repoRoot = path.resolve('..', '..');
const srcDir = path.join(repoRoot, 'art-src', 'characters', charId);
const modelsDir = path.join(repoRoot, 'app', 'stage3d', 'public', 'models');

console.log(`=== Validating Character: ${charId} ===`);
let errors = [];

// 1. Check approval.yaml
const approvalPath = path.join(srcDir, 'approval.yaml');
if (!fs.existsSync(approvalPath)) {
  errors.push(`Missing approval.yaml at ${approvalPath}`);
} else {
  const approval = YAML.parse(fs.readFileSync(approvalPath, 'utf8'));
  if (approval.status !== 'approved') {
    errors.push(`approval.yaml status must be 'approved', got: ${approval.status}`);
  }
  if (!approval.commercial_use_permitted) {
    errors.push('approval.yaml commercial_use_permitted must be true');
  }
  if (!approval.child_appropriate) {
    errors.push('approval.yaml child_appropriate check must be true');
  }
  console.log(`✓ approval.yaml verified (reviewer: ${approval.reviewer}, license: ${approval.license})`);
}

// 2. Check manifest
const manifestPath = path.join(modelsDir, `${charId}.manifest.json`);
if (!fs.existsSync(manifestPath)) {
  errors.push(`Missing manifest at ${manifestPath}`);
} else {
  console.log(`✓ Manifest verified: ${manifestPath}`);
}

// Helper to inspect GLB JSON chunk
function readGlbJson(glbBuffer) {
  if (glbBuffer.length < 20) {
    throw new Error('GLB file too small');
  }
  const magic = glbBuffer.readUInt32LE(0);
  if (magic !== 0x46546c67) {
    throw new Error('Invalid GLB magic header');
  }
  const jsonChunkLen = glbBuffer.readUInt32LE(12);
  const jsonChunkType = glbBuffer.readUInt32LE(16);
  if (jsonChunkType !== 0x4e4f534a) {
    throw new Error('First chunk is not JSON');
  }
  const jsonStr = glbBuffer.toString('utf8', 20, 20 + jsonChunkLen);
  return JSON.parse(jsonStr);
}

const TIER_BUDGETS = {
  low: { maxTriangles: 6000, maxFileSize: 1 * 1024 * 1024 },
  medium: { maxTriangles: 12000, maxFileSize: 2 * 1024 * 1024 },
  high: { maxTriangles: 25000, maxFileSize: 5 * 1024 * 1024 },
};

const REQUIRED_CLIPS = ['idle', 'think', 'encourage', 'happy', 'celebrate', 'confused'];

// 3. Inspect each LOD GLB
for (const [tier, budget] of Object.entries(TIER_BUDGETS)) {
  const glbPath = path.join(modelsDir, `${charId}.${tier}.glb`);
  if (!fs.existsSync(glbPath)) {
    errors.push(`Missing LOD model: ${glbPath}`);
    continue;
  }

  const stat = fs.statSync(glbPath);
  if (stat.size > budget.maxFileSize) {
    errors.push(`${tier} GLB exceeds size budget: ${stat.size} > ${budget.maxFileSize}`);
  }

  const buffer = fs.readFileSync(glbPath);
  let gltf;
  try {
    gltf = readGlbJson(buffer);
  } catch (err) {
    errors.push(`Failed to parse ${glbPath}: ${err.message}`);
    continue;
  }

  // Count triangles
  let totalTriangles = 0;
  if (gltf.meshes) {
    for (const mesh of gltf.meshes) {
      for (const prim of mesh.primitives || []) {
        if (prim.indices !== undefined) {
          const acc = gltf.accessors[prim.indices];
          if (acc) totalTriangles += acc.count / 3;
        }
      }
    }
  }

  if (totalTriangles > budget.maxTriangles) {
    errors.push(`${tier} triangles (${totalTriangles}) exceed budget (${budget.maxTriangles})`);
  }

  // Check bones
  let boneCount = 0;
  if (gltf.skins && gltf.skins.length > 0) {
    boneCount = gltf.skins[0].joints ? gltf.skins[0].joints.length : 0;
  }
  if (boneCount > 60) {
    errors.push(`${tier} bone count (${boneCount}) exceeds maximum of 60`);
  }

  // Check materials
  const matCount = gltf.materials ? gltf.materials.length : 0;
  if (matCount > 3) {
    errors.push(`${tier} materials (${matCount}) exceed maximum of 3`);
  }

  // Check head bone present
  const hasHead = (gltf.nodes || []).some((n) => n.name && n.name.toLowerCase().includes('head'));
  if (!hasHead) {
    errors.push(`${tier} is missing required 'Head' bone for procedural look-at`);
  }

  // Check animation clips
  const clipNames = (gltf.animations || []).map((a) => a.name);
  for (const req of REQUIRED_CLIPS) {
    if (!clipNames.includes(req)) {
      errors.push(`${tier} is missing required animation clip: '${req}'`);
    }
  }

  console.log(
    `✓ ${tier} LOD verified: ${totalTriangles} tris, ${boneCount} bones, ${matCount} materials, ${stat.size} bytes`
  );
}

if (errors.length > 0) {
  console.error('\n❌ Character pipeline validation failed:');
  for (const err of errors) {
    console.error(`  - ${err}`);
  }
  process.exit(1);
} else {
  console.log('\n✅ All character pipeline validation checks passed!');
}
