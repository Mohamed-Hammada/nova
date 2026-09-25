# Nova 3D Stage — Design

Date: 2026-09-23 · Status: draft, awaiting review · Branch: `app-foundation`

## 1. Intent

**What the user said.** The last two commits (`fabdda5`, `6806c3a`) tried to make the game
interactive, but the result looks "too ugly". Nova needs a real 3D look, "like 3D JS", and
high-quality, highly animated characters "like actual" games. Choices made in brainstorming:

| Question | Answer |
|---|---|
| Target look | 3D cartoon (Pixar-like) |
| Where characters come from | AI 3D generators (e.g. Meshy, Tripo), then cleanup |
| Devices | Budget Android tablets (2–3 GB RAM) **and** web |
| Rendering approach | A: a three.js 3D stage embedded in the Flutter app |

**Root cause of "ugly".** The characters and props were drawn pixel by pixel in
`scripts/generate_art_assets.py` from circles and gradients. No amount of code polish makes
that look authored. The fix is to change where the art comes from (rigged, animated 3D models)
and what renders it (a real 3D engine).

**Success criteria.**
1. Bear & Apples plays end to end in a lit 3D scene, with a rigged 3D bear that visibly reacts
   (idle, thinking, encourage, happy, celebrate, confused) using skeletal animation and
   crossfades, not swapped stills.
2. The child drags 3D apples into a 3D basket with a finger. Tap-to-move, keyboard, switch
   access and screen readers still work.
3. Strong devices get the richest look (High tier) and weak ones a lighter look (§5). The tier
   is chosen automatically and adjusted during play. It holds a steady frame rate on a budget
   Android tablet and in desktop and mobile browsers. Any
   device that can't manage it gets the 2D fallback automatically, with no lost progress.
4. Everything still works offline, and no request leaves the origin (the web smoke test still passes).
5. Learning logic is unchanged: same trials, signals, mastery results, same 211+ tests green.

**Assumptions (correct me if wrong).**
- Phase 1 covers **one game (Bear & Apples), one character (the bear), one scene (forest
  clearing)**. The bunny and other games come after the pipeline is proven.
- The user operates the AI generator (account, prompts, export). Claude builds everything
  after the exported GLB: processing, validation, preview, runtime.
- iOS and Windows desktop are not phase-1 targets. They get the 2D fallback.

## 2. Architecture

```
Flutter app (unchanged shell: menus, l10n/RTL, persistence, audio, a11y, rules)
 └─ GameScreen
     ├─ Stage3DView ──(versioned JSON messages)──► stage3d bundle (three.js, TypeScript)
     │    web: same-origin iframe                     SceneDirector · CharacterActor
     │    Android: WebView                            DragController · PerfMonitor
     ├─ A11yOverlay (invisible Flutter buttons aligned to 3D objects)
     └─ 2D fallback (existing DragToCountView, re-skinned with sprites rendered from the 3D model)
```

**Unchanged:** everything in `app/lib/core/` (trials, signal mapping, mastery, adaptive),
`DragToCountController`, persistence, localization, `game_audio.dart`.

**Rule of authority.** The stage reports only what the child did (`itemDropped`). Dart runs
it through `DragToCountController` and sends back the resulting state (`setItems`). The stage
never decides correctness, counts, or progression. If the two ever disagree, Dart wins and the
stage re-syncs.

### 2.1 `app/stage3d/` (new, TypeScript + Vite + three.js)

- Built by `scripts/build_stage3d.{sh,bat}` into `app/assets/stage3d/` (`index.html`, one
  bundled `stage.js`, `models/*.glb`, `textures/`, and the meshopt decoder). The build output
  is committed so a Flutter build doesn't need Node.
- `SceneDirector`: builds a scene from a scene descriptor (JSON: ground, props, basket,
  pile area, camera pose, lighting preset). Warm cartoon lighting: hemisphere light plus one
  directional key, a toon/soft PBR look, and blob-shadow decals on the low tier.
- `CharacterActor`: loads a character GLB plus its manifest and maps the six
  `CharacterVisualState`s to clips (see §4). It adds procedural "life": blinking,
  head look-at toward the finger or the dragged apple, and squash-and-stretch on tap.
- `DragController`: raycast pick, lift, follow the finger on the table plane, drop test
  against the basket's volume, and a spring arc back to the pile on a miss.
- `PerfMonitor` + `QualityGovernor`: rolling fps and draw-call stats, the tier presets
  (§5.1) and the step-down/step-up rules (§5.3). The current tier is reported to Dart.
- Pure logic (the protocol codec, state→clip mapping, drop-hit testing, and tier selection) lives in
  modules with no three.js imports, so it can be unit tested.

### 2.2 Dart side (new, in `app/lib/ui/game/stage3d/`)

- `Stage3DTransport`: an interface with two implementations. `WebIframeTransport` uses
  `HtmlElementView` plus `postMessage` with an origin check. `AndroidWebViewTransport` uses
  `webview_flutter` plus a JavaScript channel.
- `Stage3DView`: a widget that owns the transport, handles the handshake and version check,
  and converts `DragToCountController` state into stage messages and back.
- `StageCapability`: detects the device, picks the starting tier or 2D (§5.2, §5.6), applies
  the parent override (§5.4) and remembers the last stable tier per device.
- `A11yOverlay`: the stage reports each interactive object's screen rectangle
  (`layout` message). Flutter places invisible, labeled, focusable 64dp+ buttons over those
  rectangles, so tap-to-move, keyboard, switch access and screen readers keep today's semantics.

### 2.3 Protocol (v1)

JSON messages `{v:1, type, ...}`. A shared JSON Schema lives in
`app/stage3d/protocol/protocol.schema.json`, and both sides are tested against it.

| Direction | Type | Payload |
|---|---|---|
| Dart→stage | `init` | scene id, character id, locale dir (ltr/rtl), reduced motion, quality tier |
| Dart→stage | `setItems` | `[{id, kind: target|distractor, onPlate}]` |
| Dart→stage | `character` | `{state}`, one of the six states, plus optional `pointAt: basket|pile` |
| Dart→stage | `hint` | `{showCount: bool}` (numbers float over the basket's apples) |
| Dart→stage | `freeze` | `{frozen: bool}` |
| Dart→stage | `celebrate` | none (confetti burst plus the character's celebrate clip) |
| Stage→Dart | `ready` | protocol version, tier actually used |
| Stage→Dart | `itemDropped` | `{id, zone: plate|pile}` |
| Stage→Dart | `characterTapped` | none |
| Stage→Dart | `layout` | `[{id, rect}]` for the a11y overlay |
| Dart→stage | `quality` | `{tier: low\|medium\|high, source: auto\|parent}` (initial tier or parent override) |
| Stage→Dart | `perf` | `{fps, drawCalls, tier}` every 2 s |
| Stage→Dart | `tierChanged` | `{from, to, reason}` (Dart remembers it per device) |
| Stage→Dart | `error` | `{code, message}`, which triggers the fallback |

Audio stays in Dart. It plays on Dart-side events, as it does today.

### 2.4 Hosting per platform

- **Web:** a same-origin iframe at `assets/assets/stage3d/index.html`. Messages are dropped
  unless `event.origin` equals the app's origin.
- **Android:** a WebView loading the bundled assets. `file://` pages can't `fetch` GLBs,
  so the assets are served either through androidx `WebViewAssetLoader` (an
  `https://appassets.androidplatform.net/` origin) or through a loopback HTTP server
  bound to `127.0.0.1` with a random port and a per-session token. **The first plan task is a
  spike** that picks between them on a real device. `WebViewAssetLoader` is preferred if
  `webview_flutter` lets us install it.

## 3. AI character pipeline and quality gate

### 3.1 Generation (done by the user, following a prompt sheet)

`docs/art/character-prompts.md` (written in phase 1) holds the character brief: silhouette,
proportions (big head, short limbs, **standing upright on two legs** so humanoid auto-rigs and
animation libraries apply), palette, a "no teeth, soft rounded features" rule for young
children, and an A-pose requirement. Steps:
1. Generate a front concept image, then image-to-3D in the generator.
2. Use the tool's auto-rig (humanoid). Attach library animations for each required clip.
3. Export a GLB with its clips at the generator's highest detail (≥ 25k triangles, 2048
   textures, see §5.5) and drop it into `art-src/characters/bear/` (source files, git-LFS).

The facial expressions most AI rigs lack are handled with **face texture swaps** (an eye/mouth
atlas with 6 expressions, switched per state). That's more reliable than hoping for blend shapes.

### 3.2 Processing (`tools/char_pipeline/`, Node, no Blender needed)

`node tools/char_pipeline/process.mjs bear` uses `@gltf-transform`:
- normalizes scale and origin (feet at y=0, 1 unit ≈ 1 m, facing +Z)
- renames clips to the canonical set via `art-src/characters/bear/clips.yaml`
- produces three LODs (Low/Medium/High, §5.1) from the source mesh, with WebP textures at
  512/1024/2048 (plus a normal map for High), and applies meshopt compression
- writes `app/stage3d/public/models/bear.{low,medium,high}.glb` plus `bear.manifest.json`

### 3.3 Validation (automated gate, fails the build)

`validate.mjs` checks every shipped GLB:
- each LOD within its tier's triangle and texture budget (§5.1), ≤ 60 bones, ≤ 3 materials,
  file size ≤ 1 MB (Low) / 2 MB (Medium) / 5 MB (High)
- required clips present: `idle`, `think`, `encourage`, `happy`, `celebrate`, `confused` (plus optional `idle_alt`, `tap_react`, `point`)
- head bone present (for look-at), no unskinned floating parts, bounding box inside expected proportions

### 3.4 Human approval (manual gate)

`tools/char_pipeline/preview.html` is a turntable page that plays every clip at all three tiers side by side.
A character ships only when `art-src/characters/bear/approval.yaml` records who approved
it, the date, the generator used and its **license terms (commercial use permitted on the
plan used)**, plus a child-appropriateness check (nothing frightening, no uncanny faces). CI
refuses a GLB without an approval record.

### 3.5 Unblocking engineering

Until the real bear is approved, development uses a **CC0 placeholder** rigged character
(e.g. a Quaternius animal), run through the same pipeline and clearly labeled as a placeholder.
Swapping in the approved bear is a data change, not a code change.

### 3.6 On-model 2D fallback

`tools/char_pipeline/render_sprites.mjs` renders the approved GLB in headless Chrome, one
pose per state, into PNG sprites. These replace the Python-drawn character PNGs, so the
fallback matches the 3D character. `scripts/generate_art_assets.py` is retired for characters
(it may stay for simple sparkles until those are replaced).

## 4. Interaction and animation

| Game moment | `CharacterVisualState` | Clip / behavior |
|---|---|---|
| Waiting for the child | idle | `idle`, with `idle_alt` every 8–15 s, blinking, look-at following the finger |
| Child is dragging | thinking | `think`, head tracks the dragged apple |
| Hint shown | encourage | `encourage` plus `point` toward the basket, count numbers float over the apples |
| Correct answer | happy → celebrate | `happy`, then `celebrate` plus a confetti burst and a camera push-in (skipped when motion is reduced) |
| Wrong answer | confused | `confused`: a gentle head tilt, never a sad or negative clip |
| Character tapped | (any) | `tap_react` squash-and-stretch layered on top, then back to the current state |

- Crossfade 0.25 s between clips. Reactions play on an additive or override layer, then return.
- Apples: lift with a slight scale-up and a shadow that grows, drop with a bounce into the
  basket, a soft rim so they sit *inside* it, and a spring arc back on a miss. Distractor pears
  behave the same way. The rules, not the physics, decide what counts.
- **Reduced motion** (`MediaQuery.disableAnimations`) is passed in `init`: no camera moves, no
  confetti, shorter crossfades, no idle fidgeting.
- **RTL:** the pile and the basket swap sides for Arabic, matching the 2D layout's direction.

## 5. Quality tiers: best look on strong devices, lighter on weak ones

The stage has **three quality tiers**. Every device starts at the best tier it can
probably sustain, then the stage adjusts itself while the child plays. The game, the rules and
the character's animations are the same on every tier. Only visual richness changes.

### 5.1 What each tier gets

| | **Low** (budget tablets, 2–3 GB) | **Medium** (typical phones/tablets, 4–6 GB) | **High** (flagships 8 GB+, desktops) |
|---|---|---|---|
| Character model (LOD) | ≤ 6k triangles | ≤ 12k | ≤ 25k |
| Character textures | 512 | 1024 | 2048 + normal map |
| Whole scene triangles | ≤ 40k | ≤ 80k | ≤ 200k |
| Draw calls | ≤ 40 | ≤ 80 | ≤ 150 |
| Shadows | blob decals under objects | one soft shadow map (1024) | soft shadow map (2048), character self-shadowing |
| Lighting | hemisphere + key light | + rim light | + image-based lighting (baked environment map) |
| Environment | ground, basket, a few props | + trees, clouds, instanced grass | + dense grass and flowers swaying in the wind, drifting leaves and butterflies |
| Post-processing | none | FXAA | SMAA, soft bloom on sparkles, subtle toon outline, gentle depth of field on celebrate |
| Particles (confetti, sparkles) | ≤ 60 | ≤ 200 | ≤ 600 |
| Device pixel ratio cap | 1.25 | 1.75 | 2 (desktop: native) |
| Frame rate target | 30 fps steady | 60 fps (30 floor) | 60 fps |
| Animation extras | skeletal clips, blinking, look-at | + ear and tail secondary motion (spring bones) | + secondary motion on props (basket sway, apple squash) |

Reduced motion (§4) still applies on top of any tier. It turns off camera moves, confetti
and depth of field, however powerful the device is.

### 5.2 Choosing the starting tier (automatic)

On first launch `StageCapability` collects a few quick signals and picks a tier:
- **Android:** total RAM and `isLowRamDevice` (through a small platform channel or
  `device_info_plus`), Android version, and the WebView's GPU renderer string.
- **Web:** `navigator.deviceMemory` (Chromium only), `hardwareConcurrency`, WebGL2 limits
  (`MAX_TEXTURE_SIZE`, `MAX_SAMPLES`), the unmasked GPU renderer where available, and
  a mobile or desktop check.
- **A 2-second warm-up benchmark** while the scene loads, hidden behind the loading animation.
  It renders the scene at the candidate tier and measures frame time. If it's too slow, the tier
  drops one level before the child sees anything.

The rules, in plain terms: ≤ 3 GB or `isLowRamDevice` → Low; 4–6 GB → Medium; ≥ 8 GB with a
good benchmark → High. When a signal is missing (Safari hides memory, for example), start at
Medium and let the benchmark decide. GPU families known to be weak (a short list in
`stage3d/src/quality/gpu_denylist.json`) are capped at Low.

### 5.3 Adjusting while playing (automatic)

A **quality governor** watches the frame rate:
- **Step down** one tier if fps stays more than 20% below the tier's target for 5 s (for
  High, below 48 fps). Before dropping a whole tier it first lowers the pixel ratio, the
  cheapest and least visible fix.
- **Step up** at most once per session, only after 30 s comfortably above target (at least 30%
  headroom), and never back to a tier that has already failed on this device.
- Tier changes happen **between trials** (during the character's reaction), never mid-drag,
  so the child never sees a visible jump.
- The last stable tier is remembered per device, and the next launch starts there. This memory
  is reset after an app update.

### 5.4 Parent override

A small **Graphics quality** control in a parent-facing place offers **Auto** (the default),
Low, Medium, High, and **2D mode**, for families who want to save battery or who see stutter.
Choosing High on a weak device is allowed, but the fallback rules in §5.6 still protect the
child from a broken screen. The plan decides where this control lives, since the app has no
settings screen yet.

### 5.5 How the tiers are built (assets)

- The character pipeline (§3.2) produces **three LODs and three texture sizes from one
  source model**. The AI generation must therefore reach at least High-tier detail
  (≥ 25k triangles, 2048 textures). Lower tiers are reduced from it, never scaled up.
- The validator (§3.3) checks every tier against its row in §5.1.
- The stage loads only its own tier's files. Moving up a tier loads the extra files in the
  background and swaps them in between trials.
- Everything ships inside the app, so it works offline. The payload budget is **≤ 25 MB for all
  tiers together**, with Low-only files ≤ 6 MB, including three.js (tree-shaken, about 150 KB
  gzipped). If APK size becomes a problem, High-tier files can move to a Play asset pack later.
  That's out of scope for phase 1.

### 5.6 Falling back to 2D

`StageCapability` picks 2D when WebGL2 isn't available, `ready` doesn't arrive within 8 s,
the WebGL context is lost twice, even the Low tier can't hold 24 fps for 5 s, or the platform
isn't web or Android. The switch happens mid-trial without losing anything, because Dart owns
the state and the 2D view renders that same state. The fallback is remembered like a tier and
retried after an app update. No telemetry leaves the device.

## 6. Testing

- **Stage unit tests (vitest):** protocol codec against the schema, state→clip mapping,
  drop-hit tests, idle-alt scheduling, the tier-selection rules (§5.2) with fake device
  signals, and the governor (§5.3) fed synthetic fps traces: it steps down, steps up at most
  once, never changes mid-drag, and never returns to a failed tier.
- **Dart tests:** `Stage3DView` with a fake transport (handshake, version mismatch → fallback,
  `itemDropped` → controller → `setItems` round trip, `error` → 2D), the `A11yOverlay` semantics,
  and `StageCapability` decisions. All existing tests stay green.
- **Protocol contract test:** both sides' fixtures are validated against `protocol.schema.json`.
- **Pipeline tests:** `validate.mjs` on known-good and known-bad GLB fixtures.
- **Web smoke test (extended):** headless Chrome (SwiftShader WebGL) completes a session in 3D
  by sending real pointer events over the canvas, gets `ready` and `perf`, forces a context loss
  and checks the 2D fallback continues the same trial, and still sees zero off-origin requests.
- **Tier smoke test:** force each tier with the `quality` message and check that each one loads
  only its own files and completes a trial.
- **Device test (manual, run by the user):** one budget tablet, a 2–3 GB RAM class device
  (e.g. a Galaxy Tab A7 Lite or similar), which must auto-select Low and hold 30 fps; and one
  recent phone or tablet, which must auto-select Medium or High. Play 3 full sessions on each,
  then record fps and tier from the `perf` overlay, and memory. Phase 1 isn't done until this passes or the budgets are tightened.

## 7. Out of scope (phase 1)

The bunny and other characters, other games and mechanics, lip sync, a native iOS or desktop
3D host, networked or asset-streamed content, and any change to curriculum data or learning logic.

## 8. Risks and open items

- **AI output quality varies a lot.** The approval gate (§3.4) and the placeholder (§3.5) keep
  that from blocking engineering, but reaching a Pixar-like standard may take several
  generations or a paid cleanup pass by an artist.
- **Generator license:** the user must confirm that their Meshy or Tripo plan permits
  commercial use in a children's app. This is recorded in `approval.yaml`.
- **Tier detection can guess wrong**, for example in browsers that hide memory. The warm-up
  benchmark and the governor correct it within seconds, and the parent override is the last resort.
- **The High tier means more art work:** the generated model must be detailed enough for High.
  If it isn't, High uses the Medium model with High lighting and effects until a better model
  is approved.
- **Android WebView memory** on 2 GB devices is the main performance risk. It gets measured in
  the first spike, before the scene work starts.
- **Asset hosting on Android** (§2.4) is unresolved until the spike.
- Arabic strings, digit style and voice remain open, as before. Nothing here changes them.
