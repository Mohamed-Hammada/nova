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
| `app/` | The Flutter app: pure-Dart domain core (`lib/core/`), platform adapters (`lib/adapters/`), the one real mechanic (`lib/mechanics_flutter/`), and chrome (`lib/ui/`). |
| `scripts/` | Entry-point scripts that wire the two sub-projects together (see below). |

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
their own. Use the wrapper scripts instead, which always regenerate the bundle first:

```bash
./scripts/regenerate_content_bundle.sh   # just the bundle, e.g. after editing data/
./scripts/test_app.sh                    # regenerate, then flutter test
./scripts/build_apk_debug.sh             # regenerate, then flutter build apk --debug
./scripts/build_web.sh                   # regenerate, then flutter build web (output: app/build/web)
```

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
