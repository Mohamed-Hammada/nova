# Nova 3D Stage: Phase 1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Implement the Nova 3D Stage Phase 1: a Three.js + TypeScript 3D stage embedded in the Flutter app for Bear & Apples, with a rigged animated 3D character, 3 quality tiers, 2D fallback, accessibility overlay, offline safety, and automated character pipeline.

**Architecture:** A Three.js TypeScript bundle compiled via Vite into `app/assets/stage3d/` runs in a same-origin iframe (Web) or WebView (Android), communicating with Flutter via a versioned JSON protocol. Flutter's `GameScreen` hosts `Stage3DView` and `A11yOverlay`, forwarding user drag/drop events to `DragToCountController`, preserving all learning trials and signals. A seamless 2D fallback activates on low capabilities or WebGL context issues.

**Tech Stack:** Three.js, TypeScript, Vite, Vitest, Flutter (Dart), Node.js, `@gltf-transform`.

**Spec:** `docs/superpowers/specs/2026-09-23-nova-3d-stage-design.md`

## Global Constraints

- **Scope:** Phase 1 covers Bear & Apples (`game.math.bear-apples`), one character (the bear), one scene (forest clearing).
- **Domain Core Purity:** No changes to `app/lib/core/` domain logic or curriculum data. All 211+ existing tests remain green.
- **Rule of Authority:** The stage reports only physical interactions (`itemDropped`, `characterTapped`). Dart runs them through `DragToCountController` and sends back authoritative state (`setItems`). The stage never decides counts, correctness, or progression.
- **Tiers:** Three quality tiers (Low: <=6k character tris, <=40k scene tris, blob shadows, 30fps target; Medium: <=12k char tris, <=80k scene tris, soft shadow, 60fps; High: <=25k char tris, <=200k scene tris, SMAA, bloom, 60fps).
- **Reduced Motion:** If `reducedMotion` is true, disable camera moves, confetti, idle fidgeting, and use shorter crossfades.
- **RTL Support:** In Arabic / RTL mode, basket and pile swap sides.
- **Accessibility:** Stage emits `layout` rects; Flutter renders 64dp+ invisible focusable buttons over interactive elements.
- **Zero Remote Requests:** Completely offline; web smoke test must verify zero requests leave origin.
- **Git Commits:** Clean, frequent commits per task with descriptive messages.

---

## File Structure

```
d:\hamada\nova\
  docs\superpowers\plans\2026-09-23-nova-3d-stage.md
  app\
    assets\stage3d\                     (Vite build output: index.html, stage.js, models, textures)
    stage3d\
      package.json
      tsconfig.json
      vite.config.ts
      index.html
      protocol\
        protocol.schema.json
      src\
        main.ts
        protocol\
          types.ts
          codec.ts
        quality\
          tier.ts
          governor.ts
          gpu_denylist.json
        character\
          clip_mapper.ts
          fidget_timer.ts
          character_actor.ts
        interaction\
          drop_tester.ts
          drag_controller.ts
        director\
          scene_director.ts
        perf\
          perf_monitor.ts
      test\
        protocol.test.ts
        governor.test.ts
        clip_mapper.test.ts
        drop_tester.test.ts
    lib\
      ui\
        game\
          game_screen.dart             (modified: mount Stage3DView or 2D fallback)
          stage3d\
            protocol\
              stage_messages.dart
            stage3d_transport.dart
            fake_stage3d_transport.dart
            web_iframe_transport.dart
            android_webview_transport.dart
            stage_capability.dart
            stage3d_view.dart
            a11y_overlay.dart
            graphics_quality_dialog.dart
    test\
      ui\
        game\
          stage3d\
            protocol\
              stage_messages_test.dart
            stage_capability_test.dart
            stage3d_view_test.dart
            a11y_overlay_test.dart
            fallback_test.dart
  tools\
    char_pipeline\
      package.json
      validate.mjs
      process.mjs
      generate_placeholder_bear.mjs
      render_sprites.mjs
  scripts\
    build_stage3d.bat
    build_stage3d.sh
    test_stage3d.bat
    test_stage3d.sh
```

---

## Tasks

### Task 1: Protocol Schema & Codecs (TypeScript & Dart)

**Files:**
- Create: `app/stage3d/protocol/protocol.schema.json`
- Create: `app/stage3d/package.json`
- Create: `app/stage3d/tsconfig.json`
- Create: `app/stage3d/src/protocol/types.ts`
- Create: `app/stage3d/src/protocol/codec.ts`
- Create: `app/stage3d/test/protocol.test.ts`
- Create: `app/lib/ui/game/stage3d/protocol/stage_messages.dart`
- Create: `app/test/ui/game/stage3d/protocol/stage_messages_test.dart`

**Interfaces:**
- Produces: `StageMessageCodec` in TS, `StageMessage` classes in Dart (`InitMessage`, `SetItemsMessage`, `CharacterMessage`, `HintMessage`, `FreezeMessage`, `CelebrateMessage`, `ReadyMessage`, `ItemDroppedMessage`, `CharacterTappedMessage`, `LayoutMessage`, `QualityMessage`, `PerfMessage`, `TierChangedMessage`, `ErrorMessage`).

- [ ] **Step 1: Write Protocol JSON Schema**
Define `app/stage3d/protocol/protocol.schema.json` validating v1 message shapes.

- [ ] **Step 2: Write TypeScript Protocol types & Codec**
Write `app/stage3d/src/protocol/types.ts` and `codec.ts` with encode/decode and validation.

- [ ] **Step 3: Write and run TypeScript protocol tests**
Write `app/stage3d/test/protocol.test.ts`. Run with `vitest`.

- [ ] **Step 4: Write Dart protocol message classes & serialization**
Create `app/lib/ui/game/stage3d/protocol/stage_messages.dart`.

- [ ] **Step 5: Write and run Dart protocol unit tests**
Create `app/test/ui/game/stage3d/protocol/stage_messages_test.dart`. Run with `flutter test`.

- [ ] **Step 6: Commit**
`git add app/stage3d/protocol app/stage3d/src/protocol app/stage3d/test app/lib/ui/game/stage3d/protocol app/test/ui/game/stage3d/protocol`
`git commit -m "feat(stage3d): implement v1 protocol schema and codecs in TypeScript and Dart"`

---

### Task 2: Stage Quality System & Governor (Pure Logic)

**Files:**
- Create: `app/stage3d/src/quality/tier.ts`
- Create: `app/stage3d/src/quality/gpu_denylist.json`
- Create: `app/stage3d/src/quality/governor.ts`
- Create: `app/stage3d/test/governor.test.ts`
- Create: `app/lib/ui/game/stage3d/stage_capability.dart`
- Create: `app/test/ui/game/stage3d/stage_capability_test.dart`

**Interfaces:**
- Consumes: Protocol messages (`QualityTier`, `QualityMessage`, `PerfMessage`, `TierChangedMessage`).
- Produces: `QualityGovernor` (handles rolling FPS, dpr step-down, tier downgrade/upgrade rules), `StageCapability` (picks initial tier from device signals, handles parent override and persistence).

- [ ] **Step 1: Implement quality tier definitions and presets**
In `tier.ts`, specify budgets for Low, Medium, High (triangles, shadows, pixel ratio, targets).

- [ ] **Step 2: Implement QualityGovernor logic**
In `governor.ts`:
- Step down if FPS > 20% below target for 5s (first lowers pixel ratio, then steps down tier between trials).
- Step up at most once per session after 30s with > 30% headroom, never returning to failed tier.

- [ ] **Step 3: Test QualityGovernor with synthetic traces**
In `test/governor.test.ts`, feed simulated 20fps and 60fps streams and verify tier step-down and step-up rules.

- [ ] **Step 4: Implement Dart StageCapability**
In `app/lib/ui/game/stage3d/stage_capability.dart`, evaluate RAM (<3GB -> Low, 4-6GB -> Medium, >=8GB -> High), low-RAM flag, WebGL availability, and parent override.

- [ ] **Step 5: Test StageCapability in Dart**
In `test/ui/game/stage3d/stage_capability_test.dart`.

- [ ] **Step 6: Commit**
`git commit -m "feat(stage3d): implement quality governor and capability detection"`

---

### Task 3: Interaction & Animation Pure Logic

**Files:**
- Create: `app/stage3d/src/interaction/drop_tester.ts`
- Create: `app/stage3d/src/character/clip_mapper.ts`
- Create: `app/stage3d/src/character/fidget_timer.ts`
- Create: `app/stage3d/test/drop_tester.test.ts`
- Create: `app/stage3d/test/clip_mapper.test.ts`

**Interfaces:**
- Produces: `isPointInBasketVolume()`, `mapStateToClip()`, `FidgetTimer`.

- [ ] **Step 1: Write drop hit-test logic**
`drop_tester.ts` testing 3D coordinates against basket bounding sphere/box vs pile plane.

- [ ] **Step 2: Write clip mapping & fidget scheduling**
`clip_mapper.ts` mapping `idle`, `thinking`, `encourage`, `happy`, `celebrate`, `confused` to clip names and crossfade durations. `fidget_timer.ts` generating random intervals (8-15s).

- [ ] **Step 3: Test drop_tester and clip_mapper**
Unit tests in vitest verifying accurate hit testing, clip mapping, and reduced motion overrides.

- [ ] **Step 4: Commit**
`git commit -m "feat(stage3d): add interaction drop-tester and clip-mapper logic"`

---

### Task 4: Character Pipeline, Validation Gate, and CC0 Rigged Character

**Files:**
- Create: `tools/char_pipeline/package.json`
- Create: `tools/char_pipeline/validate.mjs`
- Create: `tools/char_pipeline/process.mjs`
- Create: `tools/char_pipeline/generate_placeholder_bear.mjs`
- Create: `art-src/characters/bear/clips.yaml`
- Create: `art-src/characters/bear/approval.yaml`
- Output: `app/stage3d/public/models/bear.low.glb`, `bear.medium.glb`, `bear.high.glb`, `bear.manifest.json`

**Interfaces:**
- Produces: Validated, rigged cartoon character GLB assets with animations (`idle`, `think`, `encourage`, `happy`, `celebrate`, `confused`, `idle_alt`, `tap_react`, `point`).

- [ ] **Step 1: Implement validator**
`tools/char_pipeline/validate.mjs`: enforce budgets (<=25k tris for High, <=12k for Med, <=6k for Low, <=60 bones, <=3 materials, required animation clips).

- [ ] **Step 2: Implement CC0 character generator script**
`generate_placeholder_bear.mjs` generates a valid rigged GLTF/GLB cartoon character with skeletal hierarchy (Root, Spine, Neck, Head, LeftArm, RightArm, LeftLeg, RightLeg), vertex skinning weights, and keyframe animations for all required clips.

- [ ] **Step 3: Run pipeline and generate LODs**
Run script to output `bear.low.glb`, `bear.medium.glb`, `bear.high.glb`, and `bear.manifest.json`.

- [ ] **Step 4: Run validate.mjs**
Ensure validation passes with 0 errors.

- [ ] **Step 5: Commit**
`git commit -m "feat(pipeline): create character pipeline validator and CC0 rigged bear character"`

---

### Task 5: Three.js 3D Stage Runtime

**Files:**
- Create: `app/stage3d/vite.config.ts`
- Create: `app/stage3d/index.html`
- Create: `app/stage3d/src/main.ts`
- Create: `app/stage3d/src/director/scene_director.ts`
- Create: `app/stage3d/src/character/character_actor.ts`
- Create: `app/stage3d/src/interaction/drag_controller.ts`
- Create: `app/stage3d/src/perf/perf_monitor.ts`
- Create: `scripts/build_stage3d.bat`
- Create: `scripts/build_stage3d.sh`

**Interfaces:**
- Produces: Bundled HTML/JS/GLB in `app/assets/stage3d/` containing the full interactive 3D stage.

- [ ] **Step 1: Configure Vite and build pipeline**
Set up `vite.config.ts` with single-bundle or static output into `app/assets/stage3d/`.

- [ ] **Step 2: Implement SceneDirector**
Set up Three.js scene: clearing ground, 3D basket, table/pile area, lighting (hemisphere, directional key, shadows), props based on tier, RTL support (swap basket and pile positions when `localeDir === 'rtl'`).

- [ ] **Step 3: Implement CharacterActor**
Load GLB model, set up AnimationMixer, crossfading between clips (0.25s), procedural head look-at toward finger or dragged apple, eye blinking, tap squash-and-stretch.

- [ ] **Step 4: Implement DragController**
Raycasting to select apple, lift with scale and shadow growth, drag plane translation, basket drop test, spring arc back to pile on miss, emit `itemDropped`, emit `layout` screen coordinates for a11y.

- [ ] **Step 5: Implement PerfMonitor & Stage bootstrap**
Track FPS and draw calls, emit `perf` every 2s, wire protocol listener in `main.ts`, send `ready` on scene initialization.

- [ ] **Step 6: Build bundle to app/assets/stage3d**
Run build script and verify committed bundle.

- [ ] **Step 7: Commit**
`git commit -m "feat(stage3d): implement Three.js 3D stage runtime and assets bundle"`

---

### Task 6: Dart Stage3D Transport & View Components

**Files:**
- Create: `app/lib/ui/game/stage3d/stage3d_transport.dart`
- Create: `app/lib/ui/game/stage3d/fake_stage3d_transport.dart`
- Create: `app/lib/ui/game/stage3d/web_iframe_transport.dart`
- Create: `app/lib/ui/game/stage3d/android_webview_transport.dart`
- Create: `app/lib/ui/game/stage3d/stage3d_view.dart`
- Create: `app/lib/ui/game/stage3d/a11y_overlay.dart`
- Create: `app/test/ui/game/stage3d/stage3d_view_test.dart`
- Create: `app/test/ui/game/stage3d/a11y_overlay_test.dart`

**Interfaces:**
- Produces: `Stage3DView` widget that bridges `DragToCountController` and the 3D stage, and `A11yOverlay` providing accessible tap targets.

- [ ] **Step 1: Implement Stage3DTransport and FakeStage3DTransport**
Abstract interface with `sendMessage`, `messageStream`, `initialize`, `dispose`. `FakeStage3DTransport` implements fake round-trips for test environments.

- [ ] **Step 2: Implement WebIframeTransport**
Uses `HtmlElementView` and `postMessage` with strict origin verification.

- [ ] **Step 3: Implement Stage3DView widget**
Handles handshake with 8-second timeout, state synchronization with `DragToCountController`, and error handling triggering 2D fallback.

- [ ] **Step 4: Implement A11yOverlay**
Renders invisible Flutter buttons sized at least 64dp positioned at rects received from `layout` messages for full screen-reader and switch access support.

- [ ] **Step 5: Test Stage3DView and A11yOverlay**
Test using `FakeStage3DTransport` under `flutter test`.

- [ ] **Step 6: Commit**
`git commit -m "feat(stage3d): implement Stage3DView, transport layer, and a11y overlay"`

---

### Task 7: Game Integration, Parent Override, and 2D Seamless Fallback

**Files:**
- Modify: `app/pubspec.yaml` (register `assets/stage3d/`)
- Modify: `app/lib/ui/game/game_screen.dart`
- Create: `app/lib/ui/game/stage3d/graphics_quality_dialog.dart`
- Create: `app/test/ui/game/stage3d/fallback_test.dart`

**Interfaces:**
- Produces: Seamless switching between 3D stage and 2D view; parent graphics quality selector.

- [ ] **Step 1: Register stage3d assets in pubspec.yaml**
Add `assets/stage3d/` to `flutter.assets`.

- [ ] **Step 2: Update GameScreen to support 3D stage and fallback**
In `GameScreen`, render `Stage3DView` when 3D is capable and active. If `StageCapability` signals fallback, WebGL context is lost, or parent selects 2D, seamlessly render existing 2D `DragToCountView` without resetting controller state or trial index.

- [ ] **Step 3: Add parent Graphics Quality selector**
Create `GraphicsQualityDialog` allowing selection between Auto, Low, Medium, High, and 2D mode.

- [ ] **Step 4: Write fallback tests**
Verify that a fallback triggered during a trial maintains item counts, trial progression, and controller state.

- [ ] **Step 5: Run all Flutter tests**
Ensure all existing 211+ tests and all new tests pass.

- [ ] **Step 6: Commit**
`git commit -m "feat(game): integrate 3D stage into GameScreen with seamless 2D fallback and quality override"`

---

### Task 8: On-Model 2D Fallback Sprite Rendering

**Files:**
- Create: `tools/char_pipeline/render_sprites.mjs`
- Update: 2D character sprites in `app/assets/art/characters/bear/`

**Interfaces:**
- Produces: 2D PNG sprites rendered from the 3D character model for the 6 visual states.

- [ ] **Step 1: Write headless sprite renderer**
`tools/char_pipeline/render_sprites.mjs` to render the approved character model into 2D sprites matching the 6 states (`idle`, `thinking`, `encourage`, `happy`, `celebrate`, `confused`).

- [ ] **Step 2: Generate and place sprite assets**
Export sprites to `app/assets/art/characters/bear/` so the 2D fallback is visually on-model.

- [ ] **Step 3: Commit**
`git commit -m "feat(art): render on-model 2D fallback character sprites from 3D model"`

---

### Task 9: End-to-End Verification & Web Smoke Test Extension

**Files:**
- Modify: `scripts/web_smoke_test.bat` & `scripts/web_smoke_test.sh`
- Create: `scripts/test_stage3d.bat` & `scripts/test_stage3d.sh`

- [ ] **Step 1: Verify all stage3d unit tests**
Run `npm test` in `app/stage3d` (all Vitest tests green).

- [ ] **Step 2: Verify character pipeline**
Run `node tools/char_pipeline/validate.mjs` (0 errors).

- [ ] **Step 3: Verify all Flutter tests**
Run `flutter test` in `app` (all 211+ tests + new tests pass).

- [ ] **Step 4: Verify web smoke test and zero off-origin requests**
Run `scripts/web_smoke_test.bat` to confirm build succeeds, iframe loads, and no network requests leave origin.

- [ ] **Step 5: Final review and commit**
`git commit -m "chore: complete 3D stage verification and smoke tests"`
