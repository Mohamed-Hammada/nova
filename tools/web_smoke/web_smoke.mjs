// End-to-end smoke test of the BUILT web app (app/build/web) in a real,
// headless Chrome -- no test framework, no npm packages: Node's built-in
// WebSocket speaks the Chrome DevTools Protocol directly.
//
// It proves, against the real compiled content and real browser storage:
//   1. the app boots and loads nothing from any other origin;
//   2. a child can play a full session with real pointer events;
//   3. the session's mastery result shows in the grown-ups view;
//   4. that result survives a page reload AND a full browser restart
//      (drift/SQLite-on-WebAssembly persisting to browser storage).
//
// Usage: node tools/web_smoke/web_smoke.mjs [--port 8787] [--chrome <path>]
// Normally run through scripts/web_smoke_test.(sh|bat), which builds and
// serves the app first.
import { spawn } from 'node:child_process';
import { existsSync, mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const args = Object.fromEntries(process.argv.slice(2).reduce((acc, a, i, all) => (a.startsWith('--') ? [...acc, [a.slice(2), all[i + 1]]] : acc), []));
const appPort = Number(args.port ?? 8787);
const appOrigin = `http://127.0.0.1:${appPort}`;
const debugPort = 9333 + Math.floor(Math.random() * 500);
const chromePath = args.chrome ?? [
  process.env.CHROME_PATH,
  'C:/Program Files/Google/Chrome/Application/chrome.exe',
  'C:/Program Files (x86)/Google/Chrome/Application/chrome.exe',
  '/usr/bin/google-chrome',
  '/usr/bin/chromium',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
].find((p) => p && existsSync(p));
if (!chromePath) fail('Chrome not found; pass --chrome <path> or set CHROME_PATH');

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function fail(message) {
  console.error(`FAIL: ${message}`);
  process.exitCode = 1;
  throw new Error(message);
}
const step = (message) => console.log(`- ${message}`);

// One browser profile for the whole run, so storage persists across the
// reload and the restart exactly as it would for a real user.
const profile = mkdtempSync(join(tmpdir(), 'nova-web-smoke-'));
const foreignRequests = new Set();
const consoleLines = [];
let chrome;

async function launch() {
  chrome = spawn(chromePath, [
    '--headless=new', `--remote-debugging-port=${debugPort}`, `--user-data-dir=${profile}`,
    '--no-first-run', '--no-default-browser-check', '--window-size=1280,900', '--lang=en-US', 'about:blank',
  ], { stdio: 'ignore' });
  for (let i = 0; i < 100; i++) {
    try {
      const targets = await (await fetch(`http://127.0.0.1:${debugPort}/json`)).json();
      const page = targets.find((t) => t.type === 'page');
      if (page) return connect(page.webSocketDebuggerUrl);
    } catch {}
    await sleep(100);
  }
  fail('Chrome did not expose a debugging endpoint');
}

async function stop() {
  if (!chrome) return;
  const exited = new Promise((r) => chrome.once('exit', r));
  chrome.kill();
  await Promise.race([exited, sleep(5000)]);
  chrome = null;
}

function connect(url) {
  const ws = new WebSocket(url);
  let nextId = 1;
  const pending = new Map();
  ws.addEventListener('message', (event) => {
    const msg = JSON.parse(event.data);
    if (msg.id && pending.has(msg.id)) {
      const { resolve, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? reject(new Error(msg.error.message)) : resolve(msg.result);
    } else if (msg.method === 'Runtime.consoleAPICalled') {
      consoleLines.push(`[${msg.params.type}] ${msg.params.args.map((a) => a.value ?? a.description ?? '').join(' ')}`);
    } else if (msg.method === 'Runtime.exceptionThrown') {
      consoleLines.push(`[exception] ${msg.params.exceptionDetails.exception?.description ?? msg.params.exceptionDetails.text}`);
    } else if (msg.method === 'Log.entryAdded') {
      consoleLines.push(`[${msg.params.entry.level}] ${msg.params.entry.text} ${msg.params.entry.url ?? ''}`);
    } else if (msg.method === 'Network.requestWillBeSent') {
      const u = msg.params.request.url;
      if (/^(https?|wss?):/.test(u) && !u.startsWith(appOrigin)) foreignRequests.add(u);
    }
  });
  const send = (method, params = {}) => new Promise((resolve, reject) => {
    const id = nextId++;
    pending.set(id, { resolve, reject });
    ws.send(JSON.stringify({ id, method, params }));
  });
  return new Promise((resolve) => ws.addEventListener('open', () => resolve({ send, close: () => ws.close() })));
}

async function evaluate(cdp, expression) {
  const { result, exceptionDetails } = await cdp.send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true });
  if (exceptionDetails) fail(`page script failed: ${exceptionDetails.text}`);
  return result.value;
}

// What the page announces: Chrome's own accessibility tree, i.e. exactly
// what a screen reader receives from Flutter's semantics.
async function semanticsText(cdp) {
  const { nodes } = await cdp.send('Accessibility.getFullAXTree');
  return [...new Set(nodes.map((n) => n.name?.value?.trim()).filter(Boolean))].join(' | ');
}

async function waitFor(cdp, predicate, what, timeoutMs = 20000) {
  const end = Date.now() + timeoutMs;
  while (Date.now() < end) {
    const text = await semanticsText(cdp);
    if (predicate(text)) return text;
    await sleep(150);
  }
  fail(`timed out waiting for ${what}; screen shows: ${(await semanticsText(cdp)).slice(0, 300)}`);
}

// Clicks the centre of the first semantics node whose own label is [label],
// with real mouse events (the same path a child's tap takes).
async function click(cdp, label, { index = 0 } = {}) {
  const rect = await evaluate(cdp, `(() => {
    const nodes = [...document.querySelectorAll('flt-semantics')].filter((n) => {
      const own = [...n.childNodes].filter((c) => c.nodeType === 3 || c.tagName === 'SPAN').map((c) => c.textContent).join('').trim();
      return (own === ${JSON.stringify(label)} || n.getAttribute('aria-label') === ${JSON.stringify(label)}) && n.getAttribute('aria-disabled') !== 'true';
    });
    const n = nodes[${index}];
    if (!n) return null;
    const r = n.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  })()`);
  if (!rect) fail(`no enabled "${label}" on screen`);
  for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased']) {
    await cdp.send('Input.dispatchMouseEvent', { type, x: rect.x, y: rect.y, button: 'left', buttons: type === 'mousePressed' ? 1 : 0, clickCount: 1 });
  }
  await sleep(350);
}

async function openApp(cdp) {
  await cdp.send('Network.enable');
  await cdp.send('Page.enable');
  await cdp.send('Runtime.enable');
  await cdp.send('Log.enable');
  await cdp.send('Page.navigate', { url: `${appOrigin}/` });
  // Wait for Flutter, then switch on its accessibility tree.
  for (let i = 0; i < 200; i++) {
    if (await evaluate(cdp, `!!document.querySelector('flt-semantics-placeholder')`)) break;
    await sleep(100);
  }
  await evaluate(cdp, `document.querySelector('flt-semantics-placeholder')?.click(), true`);
  return waitFor(cdp, (t) => t.includes("Bear's Apples"), 'the home screen');
}

async function readProgress(cdp) {
  await click(cdp, 'For grown-ups');
  // The mastery summary appears once the local database has answered.
  return waitFor(cdp, (t) => /Step \d of 4/.test(t), 'the progress screen with a mastery state');
}

try {
  let cdp = await launch();
  step('boot');
  await openApp(cdp);

  const before = await readProgress(cdp);
  if (!before.includes('Not yet')) fail(`a fresh profile should show "Not yet"; got: ${before.slice(0, 400)}`);
  step('fresh profile shows "Not yet"');
  await click(cdp, 'Back');
  await waitFor(cdp, (t) => t.includes("Bear's Apples"), 'home');

  step('play a full session');
  await click(cdp, "Bear's Apples. Play");
  let trials = 0;
  for (;;) {
    const text = await waitFor(cdp, (t) => /Give the bear (\d+) apple/.test(t) || t.includes('All done!'), 'a trial or completion');
    if (text.includes('All done!')) break;
    const requested = Number(text.match(/Give the bear (\d+) apple/)[1]);
    for (let i = 0; i < requested; i++) await click(cdp, 'Apple');
    await click(cdp, 'Done');
    await waitFor(cdp, (t) => t.includes("That's just right"), 'correct feedback');
    await click(cdp, 'Next');
    trials++;
    if (trials > 20) fail('session did not end');
  }
  step(`completed ${trials} trials, all correct`);

  await click(cdp, 'For grown-ups');
  const after = await waitFor(cdp, (t) => /Step \d of 4/.test(t), 'progress after the session');
  if (!after.includes('Secure')) fail(`expected Secure after a perfect, unhinted session; got: ${after.slice(0, 300)}`);
  step('grown-ups view shows Secure');

  step('reload the page');
  await openApp(cdp);
  const reloaded = await readProgress(cdp);
  if (!reloaded.includes('Secure.')) fail(`progress was lost on reload; screen shows: ${reloaded.slice(0, 500)}`);
  step('Secure survives a reload');

  step('restart the browser (same profile)');
  cdp.close();
  await stop();
  cdp = await launch();
  await openApp(cdp);
  if (!(await readProgress(cdp)).includes('Secure')) fail('progress was lost across a browser restart');
  step('Secure survives a browser restart');
  cdp.close();

  if (foreignRequests.size) fail(`requests left the app's origin:\n  ${[...foreignRequests].join('\n  ')}`);
  step(`no request left ${appOrigin}`);
  console.log('PASS: web app plays, persists progress locally, and stays on its own origin');
} catch (error) {
  if (consoleLines.length) console.error(`browser console:\n  ${consoleLines.slice(-25).join('\n  ')}`);
  if (!process.exitCode) {
    console.error(`FAIL: ${error.message}`);
    process.exitCode = 1;
  }
} finally {
  await stop();
  rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 200 });
}
