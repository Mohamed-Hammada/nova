// Automatic 2D fallback render: renders headless fixed-perspective snapshots
// of each visual state (idle, happy, thinking, celebrate, confused, encourage)
// at 512x512 into app/assets/art/characters/<char_id>_<state>.png, guaranteeing
// visual consistency with the 3D model when falling back to 2D.

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { spawn } from 'node:child_process';
import { tmpdir } from 'node:os';

const charId = process.argv[2] || 'bear';
const repoRoot = path.resolve('..', '..');
const modelPath = path.join(repoRoot, 'app', 'stage3d', 'public', 'models', `${charId}.high.glb`);
const outDir = path.join(repoRoot, 'app', 'assets', 'art', 'characters');
const threeDir = path.join(repoRoot, 'app', 'stage3d', 'node_modules', 'three');

if (!fs.existsSync(modelPath)) {
  console.error(`Model not found at: ${modelPath}`);
  process.exit(1);
}

const chromeCandidates = [
  process.env.CHROME_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
];
const chromePath = chromeCandidates.find((p) => p && fs.existsSync(p));

if (!chromePath) {
  console.warn('Chrome executable not found. Skipping headless 3D sprite rendering.');
  process.exit(0);
}

const htmlContent = `<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <style>body { margin: 0; background: transparent; overflow: hidden; }</style>
  <script type="importmap">
  {
    "imports": {
      "three": "/three/build/three.module.js"
    }
  }
  </script>
</head>
<body>
  <script type="module">
    import * as THREE from '/three/build/three.module.js';
    import { GLTFLoader } from '/three/examples/jsm/loaders/GLTFLoader.js';

    window.runRender = async function(size = 512) {
      const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true, preserveDrawingBuffer: true });
      renderer.setSize(size, size);
      renderer.setPixelRatio(1);
      renderer.outputColorSpace = THREE.SRGBColorSpace;
      document.body.appendChild(renderer.domElement);

      const scene = new THREE.Scene();
      const camera = new THREE.PerspectiveCamera(32, 1, 0.1, 100);
      camera.position.set(0, 1.0, 3.2);
      camera.lookAt(0, 0.75, 0);

      const ambientLight = new THREE.AmbientLight(0xffffff, 1.4);
      scene.add(ambientLight);

      const dirLight = new THREE.DirectionalLight(0xfff5ea, 1.8);
      dirLight.position.set(2, 4, 3);
      scene.add(dirLight);

      const fillLight = new THREE.DirectionalLight(0xddeeff, 0.8);
      fillLight.position.set(-2, 2, -1);
      scene.add(fillLight);

      const loader = new GLTFLoader();
      const gltf = await new Promise((resolve, reject) => {
        loader.load('/model.glb', resolve, undefined, reject);
      });

      scene.add(gltf.scene);

      const mixer = new THREE.AnimationMixer(gltf.scene);
      const clips = {};
      for (const clip of gltf.animations) {
        clips[clip.name] = clip;
      }

      const stateClips = {
        idle: 'idle',
        thinking: 'think',
        encourage: 'encourage',
        happy: 'happy',
        celebrate: 'celebrate',
        confused: 'confused'
      };

      const results = {};

      for (const [state, clipName] of Object.entries(stateClips)) {
        mixer.stopAllAction();
        const clip = clips[clipName] || clips['idle'];
        if (clip) {
          const action = mixer.clipAction(clip);
          action.play();
          mixer.setTime(Math.min(0.5, clip.duration * 0.35));
        }
        renderer.render(scene, camera);
        results[state] = renderer.domElement.toDataURL('image/png');
      }

      return results;
    };
    window.isReady = true;
  </script>
</body>
</html>`;

const server = http.createServer((req, res) => {
  const url = req.url.split('?')[0];
  if (url === '/' || url === '/index.html') {
    res.writeHead(200, { 'Content-Type': 'text/html' });
    res.end(htmlContent);
  } else if (url.startsWith('/three/')) {
    const rel = url.slice('/three/'.length);
    const target = path.join(threeDir, rel);
    if (fs.existsSync(target) && fs.statSync(target).isFile()) {
      res.writeHead(200, { 'Content-Type': 'application/javascript' });
      fs.createReadStream(target).pipe(res);
    } else {
      res.writeHead(404);
      res.end();
    }
  } else if (url === '/model.glb') {
    res.writeHead(200, { 'Content-Type': 'model/gltf-binary' });
    fs.createReadStream(modelPath).pipe(res);
  } else {
    res.writeHead(404);
    res.end();
  }
});

server.listen(0, '127.0.0.1', async () => {
  const port = server.address().port;
  const debugPort = 9400 + Math.floor(Math.random() * 500);
  const profileDir = fs.mkdtempSync(path.join(tmpdir(), 'nova-render-'));

  const chrome = spawn(chromePath, [
    '--headless=new',
    `--remote-debugging-port=${debugPort}`,
    `--user-data-dir=${profileDir}`,
    '--no-first-run',
    '--no-default-browser-check',
    '--use-gl=angle',
    'about:blank'
  ], { stdio: 'ignore' });

  const cleanup = () => {
    try { chrome.kill(); } catch {}
    try { fs.rmSync(profileDir, { recursive: true, force: true }); } catch {}
    server.close();
  };

  try {
    // Wait for Chrome to listen on debugPort
    let pageWsUrl = null;
    for (let i = 0; i < 50; i++) {
      await new Promise(r => setTimeout(r, 100));
      try {
        const resp = await fetch(`http://127.0.0.1:${debugPort}/json`);
        const targets = await resp.json();
        const page = targets.find(t => t.type === 'page');
        if (page) {
          pageWsUrl = page.webSocketDebuggerUrl;
          break;
        }
      } catch {}
    }

    if (!pageWsUrl) {
      throw new Error('Failed to connect to headless Chrome debugger');
    }

    const ws = new WebSocket(pageWsUrl);
    let msgId = 0;
    const pending = new Map();

    ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.method === 'Runtime.consoleAPICalled') {
        console.log('BROWSER CONSOLE:', ...msg.params.args.map(a => a.value ?? a.description ?? ''));
      }
      if (msg.method === 'Runtime.exceptionThrown') {
        console.error('BROWSER EXCEPTION:', msg.params.exceptionDetails);
      }
      if (pending.has(msg.id)) {
        const { resolve, reject } = pending.get(msg.id);
        pending.delete(msg.id);
        if (msg.error) reject(new Error(msg.error.message));
        else resolve(msg.result);
      }
    };

    await new Promise((resolve, reject) => {
      ws.onopen = resolve;
      ws.onerror = reject;
    });

    const send = (method, params = {}) => {
      const id = ++msgId;
      return new Promise((resolve, reject) => {
        pending.set(id, { resolve, reject });
        ws.send(JSON.stringify({ id, method, params }));
      });
    };

    await send('Page.enable');
    await send('Runtime.enable');
    await send('Page.navigate', { url: `http://127.0.0.1:${port}/index.html` });

    // Poll until window.isReady is true
    let isReady = false;
    for (let i = 0; i < 100; i++) {
      await new Promise(r => setTimeout(r, 100));
      const readyRes = await send('Runtime.evaluate', {
        expression: 'Boolean(window.isReady)',
        returnByValue: true
      });
      if (readyRes.result?.value === true) {
        isReady = true;
        break;
      }
    }

    if (!isReady) {
      throw new Error('Timed out waiting for renderer page initialization');
    }

    console.log(`Rendering 2D fallback sprites for character: ${charId}...`);
    const evalRes = await send('Runtime.evaluate', {
      expression: 'window.runRender(512)',
      awaitPromise: true,
      returnByValue: true
    });

    const sprites = evalRes.result?.value;
    if (!sprites || typeof sprites !== 'object') {
      throw new Error(`Renderer returned invalid sprite dictionary: ${JSON.stringify(evalRes)}`);
    }

    fs.mkdirSync(outDir, { recursive: true });

    for (const [state, dataUrl] of Object.entries(sprites)) {
      const base64Data = dataUrl.replace(/^data:image\/png;base64,/, '');
      const buffer = Buffer.from(base64Data, 'base64');
      const filename = `${charId}_${state}.png`;
      const filePath = path.join(outDir, filename);
      fs.writeFileSync(filePath, buffer);
      console.log(`  ✓ ${filename} (512x512, ${buffer.length} bytes)`);
    }

    ws.close();
    console.log(`Successfully generated all 6 2D fallback sprites in ${outDir}`);
  } catch (err) {
    console.error('Error rendering sprites:', err);
    process.exitCode = 1;
  } finally {
    cleanup();
  }
});
