# Nova app

The Flutter client: offline-first, no backend. Build, run and test it through the scripts in
`../scripts/` (they compile the content bundle first). See the repository `README.md`, sections
"Build and test the app" and "App layout".

Before running `flutter test` or `flutter run` directly from this folder, generate the content
bundle once with `../scripts/regenerate_content_bundle.sh` (or `..\scripts\regenerate_content_bundle.bat`).

The Flutter client for Nova: Android, iOS, web and desktop from one codebase, fully offline.
See the root `README.md` for how the content bundle is built, and
`docs/superpowers/designs/2026-09-22-nova-game-platform-design.md` for the architecture.

## Layout

| Path | What it is |
|---|---|
| `lib/core/` | Pure-Dart domain: content, signals, assessment, mastery, adaptive, game runtime, and the journey (`core/journey/`: curriculum engine, activity records). No Flutter. |
| `lib/adapters/` | Platform adapters behind the core's ports (SQLite via drift, audio, content asset, clock). |
| `lib/mechanics_flutter/` | Playable mechanics. Logic lives in a plain-Dart controller; the view only renders and forwards gestures. |
| `lib/ui/` | Everything the child and parent see (below). |

## The presentation layer (`lib/ui/`)

| Path | What it is |
|---|---|
| `theme/age_band.dart` | The three age groups (2–3, 4–5, 6–8). Each has a guide character, a world, and an interface scale (bigger targets for younger children). Which games appear still comes from each game's `age_range` in the spec. |
| `design/` | The design system: tokens (including the storybook palette `NovaStory` and plum-tinted `NovaShadow`), theme, grown-up components (`NovaPage`, `NovaCard`, `NovaButton`, feedback and state views) and child-facing storybook components (`components/storybook.dart`: `NovaType` with Arabic set larger and looser, play and round buttons, direction-aware speech bubble, panel, star badge, trail progress, float, pop-in, dialog). |
| `theme/nova_theme.dart`, `theme/labels.dart` | Play-screen typography (bundled Noto Sans with Noto Sans Arabic, the same families as the design system) and world colours; `labels.dart` maps enums (age group, world, graphics setting) to localized names. All interface text lives in `lib/l10n/app_en.arb` and `app_ar.arb`; curriculum text still comes from the content bundle. |
| `theme/motion.dart` | `AmbientMotion`: switches looping decorative animation off for reduced-motion users and for widget tests. One-shot feedback animations always play. |
| `characters/character_rig.dart` | The Nova character system: a small real-time 3D renderer and one shared character template. Every companion has the same big-head proportions, eyes, soft clay finish and outfit (zip hoodie, trousers, sneakers); a character is a `CharacterLook` (colours plus species parts: ears, snout, tail, antenna). |
| `characters/character_view.dart` | Animation: idle breathing, blinking and glancing, head-tracking (`lookAt`), ten held moods (idle, happy, curious, excited, surprised, thinking, confused, encouraging, celebrating, gentle disappointment) that blend over a moment, and one-shot reactions (`happy`, `cheer`, `wave`, `eat`, `encourage`, `surprise`). |
| `scene/story_scene.dart` | `StoryScene`: the 2.5D storybook landscape every screen sits in (sky, sun, hills, rounded trees, meadow, path, props), cached, with only clouds and motes moving; mirrors in RTL and stays still with reduced motion or Low graphics. `FloatingIsland` is the stage for characters, places and stages. |
| `world/` | The places of the Nova world (`activity_world.dart`: Number Meadow, Story Woods, Sound Valley, Heart Garden, Memory Cove, Discovery Hill, Splash Pond, each with a scene theme and painted landmark) and the place screen, where activities stand as stations. |
| `journey/` | The child's journey: first-launch onboarding (name, age), the adventure map, the stage screen, the stage-complete celebration, and `play_activity.dart`, which records starts and finishes through the curriculum engine. |
| `widgets/` | Pressable 3D buttons, tilting game cards, speech bubbles, one-shot confetti, glossy apple/plate/star props. |
| `home/home_screen.dart` | Home, built around the journey: who the child is (avatar, name, companion greeting), what to do next (one "continue your journey" action from the engine's recommendation), how far they have come (a past → current → ahead strip), then places to explore and treasures. |
| `game/` | Dedicated game screens (the catalog, starting with *Bear's Apples* on the 3D stage) and their session controller. |
| `progress/progress_screen.dart` | The grown-ups view: journey stage, developmental areas (a share of activities, not a score), activity history, skill progress, then settings (child's age, spoken prompts, voice answers, face play, graphics quality). |
| `settings/` | About me (name, age, companion, world, language), grown-up settings and the permission flow, and `settings_sync.dart`, which loads saved settings at boot and saves each change. |

### Characters

| Character | Age group | Role |
|---|---|---|
| Luna the bunny | 2–3 | Guide |
| Pip the fox | 4–5 | Guide |
| Orbit the robot | 6–8 | Guide |
| Bruno the bear | all | Host of *Bear's Apples*: watches the dragged apple, eats, cheers or encourages |

To add a character, add a `CharacterKind`, a `CharacterLook` (colours plus species parts) in
`character_rig.dart`, and its names. The template gives it the shared proportions, eyes and outfit,
and the animation and mood layers work unchanged. Games that name a cast member by id (for example
Bear's Apples' `bear`) draw it through the same system.

## Games and journeys (`lib/core/play/`, `lib/ui/play/`)

- `trial_factory.dart` turns a game's current rung (chosen by the Adaptive Engine and stored per game)
  into seeded rounds, reading the rung's values against that game's anchors in `data/games`. Every
  game the journeys use has a builder; tests check each rung of each game in both languages.
- `session.dart` (`PlaySession`) is the generic `GameMechanic`: views report each response and it
  emits the same `TrialSubmitted` events as before, so assessment, mastery and adaptation are
  unchanged. Stars (1-3 from accuracy) are an engagement reward only.
- `lexicon.dart` and `stories.dart` hold the interim English/Arabic word lists, syllables, rhymes and
  short stories. They are working choices to be reviewed by language specialists and moved into the
  language packs when narration is recorded.
- `trial_views.dart` has one view per interaction; `level_screen.dart` runs a level inside its place
  (prompt in a speech bubble, hint, repeat, voice answer, companion moods, soft "let's try again",
  celebration). Games only report stars and accuracy; they hold no age rules.

## The journey (`lib/core/journey/`, `lib/ui/journey/`)

- The spec (`data/journeys/journeys.yaml`) divides each age group's journey into five stages. Each
  stage is set in a place and names the ages it is the starting point for; each level has a role
  (required, practice, challenge, optional, review) and may list prerequisites. All stages, in age
  order, are ONE continuous journey.
- `CurriculumEngine` owns every progression rule: the child's age picks the starting stage; the
  current stage is the first incomplete one from there (complete = all required activities done);
  later stages open one at a time; prerequisites lock activities; the recommendation goes required →
  practice → challenge → optional → review and varies the developmental domain. Age is only a
  starting point: the engine works from activity records, so performance-based adaptation can be
  added there later.
- The child's age is chronological and changes only when a grown-up (or "About me") changes it.
  Changing it re-positions the journey; activity records are never deleted.
- `ActivityRecord`s (first started, last played, first completed, attempts, completions, best stars,
  last accuracy) are stored through `PlayerStatePort` (drift table `activity_record_rows`, schema v3;
  the migration turns levels finished earlier into completed records).
- A "mastered" activity (finished twice with every star) describes the activity, not the child's
  skill mastery, which only the assessment pipeline decides.

## Completion, mastery and adaptation (three separate things)

- **Completion** -- did the child finish the activity? The curriculum engine decides it from the
  activity's completion criteria (all rounds played, at least one star). It drives stage progress.
- **Mastery** -- is there enough evidence that the skill is developing or secure? Only the
  assessment pipeline decides it (`GameRuntime.completeSession`: signals -> AssessmentEngine
  (performance, independence) -> MasteryEngine, thresholds from the spec). Stars and completion
  never count as mastery.
- **Adaptation** -- what should happen next, given how the child played? The Adaptive Engine
  (`AdaptiveProgressionEngine` with the swappable `AdaptiveModel`; today `RuleBasedAdaptiveModel`)
  reads the session's performance AND independence (hints, adult help; limits from the skill's
  assessment rule) and decides the next rung and scaffold: accurate and independent moves up;
  accurate only with help stays so help can fade; the productive band stays; struggling moves down
  with guided help, or at the first rung is shown how first. The rung and scaffold are saved
  (`game_rung_state`) and the next session applies them (modelled: help every round, guided: help
  on the first round; this help is logged as a hint so it never reads as independent work).

The loop end to end: activity -> game session -> learning signals -> assessment -> mastery +
adaptive decision (rung, scaffold) -> `SessionOutcome` (accuracy, hints, move, scaffold) recorded on
the activity -> `CurriculumEngine` recommendation (with `ChildEvidence`: mastery per skill) -> the
journey. The recommendation stays inside curriculum eligibility (current stage, unlocked,
prerequisites met): after a hard session it suggests practice in the same area or the same game
again (now easier; at most a few times), after accurate independent play an open challenge,
otherwise required work first (avoiding the area just played, favouring skills without secure
evidence). Home, the map and stage screens all read the one `journeyProgressProvider`.

Stage names are placeholder copy (`copy_status: draft` in `data/journeys/journeys.yaml`, counted by
the validator report); their ids are technical slugs, so wording can change without touching ids.

## Settings and personalisation

- First launch: onboarding asks the child's name and age.
- About me (tap the avatar chip): name, exact age, companion, world, language.
- Grown-ups: the child's age (the journey adapts, nothing is deleted), spoken instructions, voice
  answers, face play, graphics quality (`ui/theme/graphics.dart`: Low keeps backgrounds still and
  lighting simple for older phones; the 3D stage is used only when a 3D quality level is chosen).
- Saved through `PlayerStatePort` (drift tables `level_progress_rows`, `setting_rows`,
  `activity_record_rows`) and loaded before the first frame (`ui/settings/settings_sync.dart`).

## Voice and face (privacy by design)

- Spoken prompts use the device's text-to-speech (`adapters/speech/`). No permission needed.
- Voice answers (`adapters/device/device_ports_native.dart`) use `speech_to_text` with
  `onDevice: true`; if the device can only recognise speech in the cloud, the feature reports itself
  unavailable. `core/play/voice_match.dart` maps what was heard to an answer (numbers, pictures,
  letters, feelings in both languages); a spoken answer is scored exactly like a tap.
- Face play uses the front camera at low resolution with ML Kit's bundled on-device face detector.
  Only a few numbers (face position, smile and eye-open likelihoods) leave the detector; no frame is
  kept, shown or sent. The guide looks at the child, smiles back and plays peekaboo
  (`core/play/face_buddy.dart`); a camera badge is visible whenever the camera runs.
- Both are off until a grown-up switches them on, which triggers the OS permission prompt. Neither is
  offered on the web (browser speech recognition is cloud-based, and there is no on-device face
  detector there); the web build uses stubs, so the native plugins never enter it.
- Android manifest and iOS `Info.plist` declare the microphone and camera use. On iOS, ML Kit needs a
  deployment target of 15.5 or later in the Podfile.

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
