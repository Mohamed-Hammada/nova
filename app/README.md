# Nova app

The Flutter client for Nova: Android, iOS, web and desktop from one codebase, fully offline.
See the root `README.md` for how the content bundle is built, and
`docs/superpowers/designs/2026-09-22-nova-game-platform-design.md` for the architecture.

## Layout

| Path | What it is |
|---|---|
| `lib/core/` | Pure-Dart domain: content, signals, assessment, mastery, adaptive, game runtime. No Flutter. |
| `lib/adapters/` | Platform adapters behind the core's ports (SQLite via drift, audio, content asset, clock). |
| `lib/mechanics_flutter/` | Playable mechanics. Logic lives in a plain-Dart controller; the view only renders and forwards gestures. |
| `lib/ui/` | Everything the child and parent see (below). |

## The presentation layer (`lib/ui/`)

| Path | What it is |
|---|---|
| `theme/age_band.dart` | The three age groups (2–3, 4–5, 6–8). Each has a guide character, a world, and an interface scale (bigger targets for younger children). Which games appear still comes from each game's `age_range` in the spec. |
| `theme/nova_theme.dart`, `theme/strings.dart` | Typography (bundled Baloo Bhaijaan 2, Latin + Arabic), colours, and the app's own English/Arabic interface text. Curriculum text still comes from the content bundle. |
| `theme/motion.dart` | `AmbientMotion`: switches looping decorative animation off for reduced-motion users and for widget tests. One-shot feedback animations always play. |
| `characters/character_rig.dart` | A small real-time 3D renderer. Each character is a rig of ellipsoids with joints (head, arms, legs, ears, tail, antenna). Every frame it poses, projects and depth-sorts the parts, then shades them with key, fill, bounce, rim and specular light. Eyes, mouths and brows are surface details that turn with the head. No image assets are needed. |
| `characters/character_view.dart` | Animation: idle breathing, blinking and glancing around, head-tracking (`lookAt`), and one-shot reactions (`happy`, `cheer`, `wave`, `eat`, `encourage`), built from squash-and-stretch, anticipation and eased envelopes. |
| `scene/world_backdrop.dart` | The animated worlds: Candy Meadow (2–3), Sunny Forest (4–5), Cosmic Lab (6–8). Parallax hills, a light source with bloom, clouds or stars, particles and a vignette. |
| `widgets/` | Pressable 3D buttons, tilting game cards, speech bubbles, one-shot confetti, glossy apple/plate/star props. |
| `home_screen.dart`, `age_picker.dart`, `game_screen.dart`, `parent_view.dart` | The screens. The grown-ups area opens with a press-and-hold, so a stray tap from a child doesn't open it. |

### Characters

| Character | Age group | Role |
|---|---|---|
| Luna the bunny | 2–3 | Guide |
| Pip the fox | 4–5 | Guide |
| Orbit the robot | 6–8 | Guide |
| Bruno the bear | all | Host of *Bear's Apples*: watches the dragged apple, eats, cheers or encourages |

To add a character, add a `CharacterKind`, a model (a list of `Part`s plus joint pivots) in
`character_rig.dart`, and its names. The animation layer works for any model.

## Web

`flutter build web` works. Storage uses SQLite compiled to WebAssembly: `web/sqlite3.wasm` and
`web/drift_worker.js` are committed, and their versions must match the `sqlite3` and `drift`
entries in `pubspec.lock`. The rendering engine (CanvasKit) is loaded from the app's own
`canvaskit/` folder, not Google's CDN (see `web/index.html`), so the web app has no third-party
runtime dependency.

## Tests

`flutter test` (or `../scripts/test_app.sh`, which regenerates the content bundle first). Widget
tests switch off looping ambient animation through `ambientMotionProvider`, so `pumpAndSettle`
can settle.
