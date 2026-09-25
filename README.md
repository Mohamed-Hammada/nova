# Nova

An evidence-informed child development platform for ages 2-8 (Arabic and English first, other
languages later through language packs). This repository holds two sub-projects: **1. the Master
Curriculum Specification** (the skill graph, games, assessment rules and language packs as YAML, a
Python validator that enforces the rules, and explanatory chapters) and **2. the Game Platform
vertical slice** (a client-side, offline-first Flutter app for Android and the web that plays one real game end to end
through the full content -> assessment -> mastery -> adaptive -> persistence pipeline).

## Where things are

| Path | What it is |
|---|---|
| `docs/superpowers/specs/2026-09-21-nova-curriculum-design.md` | The curriculum design. Read it first. |
| `docs/superpowers/plans/2026-09-21-nova-curriculum-spec.md` | The task-by-task plan that built `data/` and `tools/validate/`. |
| `docs/superpowers/designs/2026-09-22-nova-game-platform-design.md` | The game platform architecture. |
| `docs/superpowers/plans/2026-09-22-nova-game-platform-vertical-slice.md` | The task-by-task plan that built `app/` and `tools/content_compiler/`. |
| `docs/curriculum/` | The eight explanatory chapters and the research log. |
| `data/` | The specification itself: `schema/` (JSON Schemas) plus YAML for skills, games, transfer tasks, evidence, parameters, assessment rules, language packs, mechanics, signals, journeys (the 50-level map per age group), i18n and audio. |
| `tools/validate/` | The validator (Python) and its tests. |
| `tools/content_compiler/` | Compiles validated `data/` into `app/assets/content/content_bundle.json`, the app's runtime content. |
| `app/` | The Flutter app (Android, iOS, desktop and web from one codebase). See "App layout" below. |
| `scripts/` | Entry-point scripts that wire the two sub-projects together, as `.sh` and `.bat` (see below). |
| `tools/web_smoke/` | A dependency-free headless-Chrome smoke test of the built web app (see below). |

## Run the validator

From `tools/validate`:

```bash
python -m venv .venv
.venv/Scripts/python.exe -m pip install -r requirements.txt
.venv/Scripts/python.exe -m pytest -q                  # the validator's own tests
.venv/Scripts/python.exe -m nova_validate --report     # validate ../../data
```

The data is valid only when the last command prints `0 error(s)`. See `tools/validate/README.md`.

## Build and test the app

`app/assets/content/content_bundle.json` is a **generated build artifact** (gitignored, never
committed): it is compiled from `data/` by `tools/content_compiler/compile.py`, which runs
`nova_validate` first and refuses to produce a bundle from invalid data. **A fresh checkout has no
bundle file**, so `flutter build`/`flutter test` from inside `app/` alone are not reproducible on
their own. Use the wrapper scripts instead, which always regenerate the bundle first and stop with a
clear error when a prerequisite is missing:

| Task | Windows | macOS / Linux / Git Bash |
|---|---|---|
| Regenerate the content bundle only | `scripts\regenerate_content_bundle.bat` | `./scripts/regenerate_content_bundle.sh` |
| Run all app tests | `scripts\test_app.bat` | `./scripts/test_app.sh` |
| Run the app in Chrome (http://localhost:8686) | `scripts\run_web.bat` | `./scripts/run_web.sh` |
| Build the web app into `app/build/web` | `scripts\build_web.bat` | `./scripts/build_web.sh` |
| Build, serve and smoke-test the web app | `scripts\web_smoke_test.bat` | `./scripts/web_smoke_test.sh` |
| Build a debug APK | `scripts\build_apk_debug.bat` | `./scripts/build_apk_debug.sh` |

Prerequisites: Flutter (3.41+) on `PATH`, and the validator's Python virtualenv at
`tools/validate/.venv` (see "Run the validator"); the smoke test also needs Node.js 22+ and Google
Chrome. Extra arguments are passed through, e.g. `scripts\test_app.bat test\ui` or
`scripts\run_web.bat -d edge`.

### The web build is self-contained

`app/build/web` is a static site: serve it with any static file server; there is no backend.
Everything it loads comes from its own origin: CanvasKit (`--no-web-resources-cdn`), the bundled
Noto Sans and Noto Sans Arabic fonts (so nothing triggers a runtime font download, including Flutter's
default Roboto), and the content bundle. The smoke test fails if any request leaves the origin.

Child progress persists in the browser through the **same** drift/SQLite adapter as on devices:
`app/lib/adapters/persistence_drift/connection.dart` picks `NativeDatabase` or SQLite compiled to
WebAssembly at compile time, and nothing above `PersistencePort` knows which. The two files the web
side needs, `app/web/sqlite3.wasm` and `app/web/drift_worker.js`, are vendored and pinned to the
versions in `app/pubspec.lock` (`app/web/sqlite_web_assets.json`, enforced by a test); after upgrading
`drift` or `sqlite3`, run `./scripts/update_web_sqlite_assets.sh`. The smoke test plays a full
session, then checks the result survives a page reload and a browser restart. Browsers may still
evict site storage under pressure (the app asks for persistent storage, which a browser may refuse),
so web is not yet a substitute for device storage for a child's only copy of their progress.

## App layout

```
app/lib/
  core/               pure Dart domain: content, signals, assessment, mastery, adaptive,
                      game runtime, mechanics (logic only), ports. No Flutter, no platform code.
  adapters/           port implementations: drift persistence (native and web connections),
                      asset content loader, audio, clock.
  mechanics_flutter/  the Flutter view of each mechanic (drag-to-count), reusable across games.
  ui/design/          the Nova design system: tokens, theme, and components (buttons, cards,
                      feedback banner, step dots, loading/empty/error states, page frame).
  ui/game/            game catalog, per-game definitions and art, and GameSessionController,
                      the view model that runs a session through GameRuntime.
  ui/home, progress, shell   the screens and the language menu.
  ui/l10n.dart        supported locales, Arabic digits, content-string lookup.
  l10n/               ARB files for UI strings (English, Arabic) and the generated AppLocalizations.
  providers.dart      the composition root; bootstrap.dart loads content with loading/error states.
```

`app/test/architecture_guard_test.dart` enforces the layering: the core imports no Flutter or
platform library; `dart:io` and FFI appear only in the native connection, browser libraries only
in the web connection; widgets never import persistence, assessment, mastery or adaptive code; and
UI code contains no hardcoded user-visible strings. UI strings live in `app/lib/l10n/*.arb`;
curriculum strings (game and skill names) keep coming from the content bundle. Text direction comes
from the locale (Arabic RTL, English LTR); all layout uses start/end geometry.

The spec now covers 36 skills (math, thinking skills, feelings, and all eight literacy slots for
both English and Arabic), 40 games and a 50-level journey for each age group (2–3, 4–5, 6–8). Every
new record is judgment-class (design inference, `verified: false`) until the research task links
verified evidence. The app plays every journey game offline, with animated 3D characters, spoken
prompts, optional voice answers and face play (on-device only, off until a grown-up allows them),
and per-child settings. See `app/README.md`.

## Ground rules for any agent working here

- **Work only inside this folder.** Do not create working copies or scratch files in temp or
  scratchpad directories; anything another agent needs must live in the project.
- The spec is the authority. Do not present any threshold or weight as validated: every
  parameter stays `provisional` until a linked calibration study exists.
- Evidence must be verified against the primary source before it is marked `verified: true`.
  Expert judgment and design inference are never recorded as empirical evidence.
- Engagement, completion and in-game performance are not evidence of learning or transfer.
- Every commit message ends with `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.
