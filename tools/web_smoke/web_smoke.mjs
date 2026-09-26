// End-to-end smoke test of the BUILT web app (app/build/web) in a real,
// headless Chrome -- no test framework, no npm packages: Node's built-in
// WebSocket speaks the Chrome DevTools Protocol directly.
//
// It proves, against the real compiled content and real browser storage:
//   1. the app boots and loads nothing from any other origin;
//   2. a child can play a full session with real pointer events;
//   3. the session's mastery result shows in the grown-ups view;
//   4. that result survives a page reload AND a full browser restart
//      (drift/SQLite-on-WebAssembly persisting to browser storage);
//   5. the product is the journey, not a category menu: Home names the
//      current adventure and never offers a choice of area; playing what
//      the journey recommends finishes a stage, which is celebrated and
//      unlocks the next; the child's age stays 4 throughout; and a grown-up
//      changing the age to 6 moves the journey there with history kept.
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

// The old category-first places. Home must never offer them.
const CATEGORY_NAMES = ['Number Meadow', 'Story Woods', 'Sound Valley', 'Heart Garden', 'Memory Cove', 'Discovery Hill', 'Splash Pond', 'Places to explore'];

// One browser profile for the whole run, so storage persists across the
// reload and the restart exactly as it would for a real user.
const profile = mkdtempSync(join(tmpdir(), 'nova-web-smoke-'));
const foreignRequests = new Set();
const consoleLines = [];
let chrome;

async function launch() {
  chrome = spawn(chromePath, [
    '--headless=new', `--remote-debugging-port=${debugPort}`, `--user-data-dir=${profile}`,
    '--no-first-run', '--no-default-browser-check', '--window-size=1280,900', '--lang=en-US',
    // Chrome refuses to sandbox as root (CI containers); only then run it unsandboxed.
    ...(process.getuid?.() === 0 ? ['--no-sandbox'] : []),
    'about:blank',
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
async function click(cdp, label, { index = 0, timeoutMs = 8000, prefix = false, scroll = false } = {}) {
  const end = Date.now() + timeoutMs;
  let rect = null;
  while (Date.now() < end) {
    rect = await evaluate(cdp, `(() => {
      const nodes = [...document.querySelectorAll('flt-semantics')].filter((n) => {
        const own = [...n.childNodes].filter((c) => c.nodeType === 3 || c.tagName === 'SPAN').map((c) => c.textContent).join('').trim();
        const name = n.getAttribute('aria-label') ?? own;
        const match = ${prefix} ? (own.startsWith(${JSON.stringify(label)}) || name.startsWith(${JSON.stringify(label)})) : (own === ${JSON.stringify(label)} || name === ${JSON.stringify(label)});
        return match && n.getAttribute('aria-disabled') !== 'true';
      });
      const n = nodes[${index}];
      if (!n) return null;
      const r = n.getBoundingClientRect();
      return { x: r.left + r.width / 2, y: r.top + r.height / 2, visible: r.top >= 0 && r.bottom <= innerHeight };
    })()`);
    if (rect && (rect.visible || !scroll)) break;
    // Off screen in a scrolling list: scroll down and look again.
    if (scroll) await cdp.send('Input.dispatchMouseEvent', { type: 'mouseWheel', x: 640, y: 450, deltaX: 0, deltaY: 300 });
    await sleep(150);
  }
  if (!rect) {
    fail(`no enabled "${label}" on screen; screen shows: ${(await semanticsText(cdp)).slice(0, 400)}`);
  }
  for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased']) {
    await cdp.send('Input.dispatchMouseEvent', { type, x: rect.x, y: rect.y, button: 'left', buttons: type === 'mousePressed' ? 1 : 0, clickCount: 1 });
  }
  await sleep(350);
}

// Taps the text field labelled [label] (a real input element in the page,
// not a semantics node) and types [text] as the keyboard would.
async function typeInto(cdp, label, text) {
  const rect = await waitForValue(cdp, `(() => {
    const field = [...document.querySelectorAll('input, textarea, flt-semantics')].find((e) =>
      e.getAttribute('aria-label') === ${JSON.stringify(label)} || e.getAttribute('placeholder') === ${JSON.stringify(label)} || e.textContent.trim() === ${JSON.stringify(label)});
    if (!field) return null;
    const r = field.getBoundingClientRect();
    return { x: r.left + r.width / 2, y: r.top + r.height / 2 };
  })()`, `the "${label}" field`);
  for (const type of ['mouseMoved', 'mousePressed', 'mouseReleased']) {
    await cdp.send('Input.dispatchMouseEvent', { type, x: rect.x, y: rect.y, button: 'left', buttons: type === 'mousePressed' ? 1 : 0, clickCount: 1 });
  }
  await sleep(400);
  await cdp.send('Input.insertText', { text });
  await sleep(400);
}

async function waitForValue(cdp, expression, what, timeoutMs = 8000) {
  const end = Date.now() + timeoutMs;
  while (Date.now() < end) {
    const value = await evaluate(cdp, expression);
    if (value) return value;
    await sleep(150);
  }
  fail(`timed out waiting for ${what}`);
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
  // A first launch asks the child's name and age; later launches open Home.
  const first = await waitFor(cdp, (t) => t.includes("What's your name?") || t.includes('For grown-ups'), 'onboarding or home');
  if (first.includes("What's your name?")) {
    step('first launch: onboarding (name Sara, age 4)');
    await typeInto(cdp, 'Your name', 'Sara');
    await click(cdp, 'Next');
    await click(cdp, '4 years old');
    await click(cdp, 'Next');
    await waitFor(cdp, (t) => t.includes('First stop: Counting Orchard'), 'the first stop of the journey');
    await click(cdp, "Let's go!");
    await waitFor(cdp, (t) => t.includes('Your adventure begins, Sara!'), 'the journey beginning, by name');
  }
  return waitFor(cdp, (t) => t.includes('For grown-ups') && t.includes('My journey'), 'the home screen');
}

// The labels of the enabled semantics nodes on screen, in order.
async function labels(cdp) {
  return evaluate(cdp, `[...document.querySelectorAll('flt-semantics')].filter((e) => e.getAttribute('aria-disabled') !== 'true').map((e) => {
    const own = [...e.childNodes].filter((c) => c.nodeType === 3 || c.tagName === 'SPAN').map((c) => c.textContent).join('').trim();
    return e.getAttribute('aria-label') ?? own;
  }).filter(Boolean)`);
}

// One round of a choice game, answers tried in order: a miss is followed by
// another try in the same round (the try-again flow), and after two misses
// the companion's hand shows the answer.
async function playChoiceRound(cdp, round) {
  for (let n = 1; n <= 4; n++) {
    if (!(await labels(cdp)).includes(`Choice ${n}`)) continue;
    await click(cdp, `Choice ${n}`, { timeoutMs: 2000 });
    await sleep(1300);
    const now = await semanticsText(cdp);
    if (now.includes('Level complete!') || !now.includes(`Round ${round} of`)) return;
  }
}

// One board of a pairs game, played by ear: a face-up card names its
// picture ("Card 2: cat"), so the test remembers what it has seen.
async function playPairsRound(cdp, round) {
  const seen = new Map();
  const faceDown = async () => (await labels(cdp)).filter((l) => /^Card \d+$/.test(l)).map((l) => Number(l.slice(5)));
  const faceOf = async (i) => (await labels(cdp)).find((l) => l.startsWith(`Card ${i}: `))?.slice(`Card ${i}: `.length);
  // The board shows every card for a moment first.
  const end = Date.now() + 10000;
  while (!(await faceDown()).length) {
    if (Date.now() > end) fail('the cards never turned face down');
    await sleep(150);
  }
  for (let turns = 0; turns < 30; turns++) {
    const down = await faceDown();
    if (!down.length || !(await semanticsText(cdp)).includes(`Round ${round} of`)) return;
    const first = down[0];
    await click(cdp, `Card ${first}`);
    const pic = await faceOf(first);
    const match = [...seen].find(([i, p]) => i !== first && p === pic && down.includes(i));
    const second = match ? match[0] : down.find((i) => i !== first && !seen.has(i)) ?? down.find((i) => i !== first);
    if (second === undefined) fail('no second card to turn');
    await click(cdp, `Card ${second}`);
    seen.set(first, pic);
    seen.set(second, await faceOf(second));
    await sleep(1100);
  }
  fail('a pairs board did not end');
}

// One round of a clap game: one beat on the drum, then Done.
async function playClapRound(cdp) {
  await click(cdp, 'Drum');
  await click(cdp, 'Done');
  await sleep(1400);
}

// Bear's Apples, played right: exactly the apples asked for.
async function playBearApples(cdp) {
  let trials = 0;
  for (;;) {
    // While the session saves, the last round is still on screen; wait it out.
    const text = await waitFor(cdp, (t) => (/Give the bear (\d+) apple/.test(t) && !t.includes('Saving')) || t.includes('All done!'), 'a trial or completion');
    if (text.includes('All done!')) return trials;
    const requested = Number(text.match(/Give the bear (\d+) apple/)[1]);
    for (let i = 0; i < requested; i++) await click(cdp, 'Apple');
    await click(cdp, 'Done');
    await waitFor(cdp, (t) => t.includes("That's just right"), 'correct feedback');
    await click(cdp, 'Next');
    if (++trials > 20) fail('session did not end');
  }
}

// Plays whatever the journey recommends, from Home's one big button to the
// end, and comes back to Home. Returns what kind of game it was.
async function playRecommended(cdp) {
  await click(cdp, 'Continue your journey', { scroll: true });
  const first = await waitFor(cdp, (t) => /Round \d+ of \d+/.test(t) || /Give the bear \d+ apple/.test(t), 'the recommended activity to start');
  if (/Give the bear/.test(first)) {
    await playBearApples(cdp);
    await click(cdp, 'Home');
    return 'apples';
  }
  let kind = 'choice';
  for (let rounds = 0; ; rounds++) {
    const text = await waitFor(cdp, (t) => /Round \d+ of \d+/.test(t) || t.includes('Level complete!'), 'a round');
    if (text.includes('Level complete!')) break;
    if (rounds > 12) fail('an activity did not end');
    const round = text.match(/Round (\d+) of/)[1];
    const now = await labels(cdp);
    if (now.includes('Drum')) {
      kind = 'clap';
      await playClapRound(cdp);
    } else if (now.some((l) => /^Card \d+/.test(l))) {
      kind = 'pairs';
      await playPairsRound(cdp, round);
    } else if (now.includes('Choice 1')) {
      await playChoiceRound(cdp, round);
    } else {
      fail(`an activity this test cannot play; screen shows: ${text.slice(0, 300)}`);
    }
  }
  await click(cdp, 'Map');
  return kind;
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
  const first = await waitFor(cdp, (t) => t.includes("Bear's Apples") && t.includes('Counting Orchard'), 'home, recommending Bear\'s Apples in Counting Orchard');
  for (const place of CATEGORY_NAMES) {
    if (first.includes(place)) fail(`Home offers the category "${place}"`);
  }
  step('Home: Counting Orchard is the current adventure, Bear\'s Apples is next, no category grid');

  step('play a full session (the journey\'s first activity)');
  await click(cdp, "Let's go!");
  const trials = await playBearApples(cdp);
  step(`completed ${trials} trials, all correct`);

  await click(cdp, 'For grown-ups');
  await waitFor(cdp, (t) => /Step \d of 4/.test(t), 'progress after the session');
  await waitFor(cdp, (t) => t.includes('Secure'), 'Secure after a perfect, unhinted session');
  step('grown-ups view shows Secure');
  // The adaptive loop reached the journey: the session's decision is recorded
  // with the activity and reported to grown-ups.
  await waitFor(cdp, (t) => t.includes('Moved up a level'), 'the adaptive decision in the activity history');
  step('the Adaptive Engine moved Bear\'s Apples up a level, recorded on the journey');

  step('reload the page');
  await openApp(cdp);
  await readProgress(cdp);
  // Each skill card loads its mastery on its own; wait for Bear's Apples' skill.
  await waitFor(cdp, (t) => t.includes('Secure.'), 'Secure after the reload (progress was lost?)');
  step('Secure survives a reload');

  step('restart the browser (same profile)');
  cdp.close();
  await stop();
  cdp = await launch();
  await openApp(cdp);
  await readProgress(cdp);
  await waitFor(cdp, (t) => t.includes('Secure'), 'Secure after a browser restart (progress was lost?)');
  step('Secure survives a browser restart');

  await click(cdp, 'Back');
  await waitFor(cdp, (t) => t.includes('For grown-ups'), 'home');

  // Home is the journey: the adventure the child is on and what comes next,
  // never a choice of area to practise.
  const home = await waitFor(cdp, (t) => t.includes('Current adventure') && t.includes('Counting Orchard') && t.includes('1 of 6 done'), 'Home: the current adventure, 1 of 6 done');
  step('Home after a session: Counting Orchard is the current adventure, 1 of 6 done');
  for (const place of CATEGORY_NAMES) {
    if (home.includes(place)) fail(`Home offers the category "${place}"`);
  }

  await click(cdp, 'Journey map', { scroll: true });
  await waitFor(cdp, (t) => t.includes('Counting Orchard. You are here') && t.includes('Story Bridge. Locked') && t.includes('Lily Pond. Locked'), 'the map: here, and locked ahead');
  step('journey map: Counting Orchard is here; Story Bridge and Lily Pond are locked');
  await click(cdp, 'Home');
  await waitFor(cdp, (t) => t.includes('Current adventure'), 'home');

  // Play whatever the journey recommends until the adventure is finished.
  const played = [];
  for (;;) {
    if (played.length > 14) fail(`Counting Orchard was not finished after ${played.length} activities: ${played.join(', ')}`);
    played.push(await playRecommended(cdp));
    const now = await waitFor(cdp, (t) => t.includes('Well done! You finished Counting Orchard!') || t.includes('Current adventure'), 'home or the celebration');
    if (now.includes('Well done! You finished Counting Orchard!')) break;
    const done = now.match(/(\d) of 6 done/)?.[1];
    step(`played the recommended activity (${played.at(-1)}); ${done ?? '?'} of 6 done`);
  }
  step(`finished Counting Orchard after ${played.length} activities: ${played.join(', ')}`);
  await waitFor(cdp, (t) => t.includes('A new adventure is waiting!') && t.includes('Story Bridge'), 'the next adventure unlocking');
  step('stage celebration: a new adventure is waiting, Story Bridge');
  await click(cdp, "Let's go!");
  await waitFor(cdp, (t) => t.includes('Current adventure') && t.includes('Story Bridge'), 'Home on Story Bridge');
  await click(cdp, 'Journey map', { scroll: true });
  await waitFor(cdp, (t) => t.includes('Counting Orchard. Done') && t.includes('Story Bridge. You are here') && t.includes('Echo Valley. Locked'), 'the map after the adventure');
  step('Home and the map moved on to Story Bridge; Counting Orchard is done');
  await click(cdp, 'Home');

  await click(cdp, 'For grown-ups');
  await waitFor(cdp, (t) => t.includes('4 years old'), 'the age in settings');
  step('the child is still 4: progress never changes the age');
  await click(cdp, 'Older', { scroll: true });
  await click(cdp, 'Older', { scroll: true });
  await waitFor(cdp, (t) => t.includes('6 years old'), 'the new age');
  await click(cdp, 'Back');
  await waitFor(cdp, (t) => t.includes('Current adventure') && t.includes('Pattern Peaks'), 'Home at the age-6 curriculum');
  await click(cdp, 'Journey map', { scroll: true });
  await waitFor(cdp, (t) => t.includes('Counting Orchard. Done') && t.includes('Pattern Peaks. You are here'), 'history kept after the age change');
  step('age 4 to 6 in settings: the journey starts at Pattern Peaks, and Counting Orchard stays done');
  cdp.close();

  if (foreignRequests.size) fail(`requests left the app's origin:\n  ${[...foreignRequests].join('\n  ')}`);
  step(`no request left ${appOrigin}`);
  console.log('PASS: web app follows the journey, persists progress locally, and stays on its own origin');
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
