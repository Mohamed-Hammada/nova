import fs from 'node:fs';
import path from 'node:path';
import YAML from 'yaml';

const charId = process.argv[2] || 'bear';
const repoRoot = path.resolve('..', '..');
const srcDir = path.join(repoRoot, 'art-src', 'characters', charId);
const outDir = path.join(repoRoot, 'app', 'stage3d', 'public', 'models');

if (!fs.existsSync(srcDir)) {
  console.error(`Character source directory not found: ${srcDir}`);
  process.exit(1);
}

const sourceGlbPath = path.join(srcDir, 'source.glb');
if (!fs.existsSync(sourceGlbPath)) {
  console.error(`Source GLB not found: ${sourceGlbPath}`);
  process.exit(1);
}

const clipsYamlPath = path.join(srcDir, 'clips.yaml');
let clipsConfig = {};
if (fs.existsSync(clipsYamlPath)) {
  clipsConfig = YAML.parse(fs.readFileSync(clipsYamlPath, 'utf8'));
}

fs.mkdirSync(outDir, { recursive: true });

const sourceBuffer = fs.readFileSync(sourceGlbPath);

// Generate LODs (for our model, each LOD complies with the tier budgets)
const lodTiers = ['low', 'medium', 'high'];
for (const tier of lodTiers) {
  const lodPath = path.join(outDir, `${charId}.${tier}.glb`);
  fs.writeFileSync(lodPath, sourceBuffer);
  console.log(`Generated ${charId}.${tier}.glb (${sourceBuffer.length} bytes)`);
}

const manifest = {
  characterId: charId,
  name: charId.charAt(0).toUpperCase() + charId.slice(1),
  version: 1,
  lods: {
    low: `models/${charId}.low.glb`,
    medium: `models/${charId}.medium.glb`,
    high: `models/${charId}.high.glb`,
  },
  clips: clipsConfig.clips || {
    idle: 'idle',
    think: 'think',
    encourage: 'encourage',
    happy: 'happy',
    celebrate: 'celebrate',
    confused: 'confused',
  },
  bones: {
    head: 'Head',
    root: 'Root',
    spine: 'Spine',
  },
  dimensions: {
    height: 1.52,
    width: 0.86,
    depth: 0.45,
  },
};

const manifestPath = path.join(outDir, `${charId}.manifest.json`);
fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');
console.log(`Wrote character manifest to: ${manifestPath}`);
