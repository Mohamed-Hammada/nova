# Nova

An evidence-informed child development platform for ages 2-8 (Arabic and English first, other
languages later through language packs). This repository holds **sub-project 1: the Master
Curriculum Specification**: the skill graph, games, assessment rules and language packs as YAML,
a Python validator that enforces the rules, and explanatory chapters. There is no app code yet.

## Where things are

| Path | What it is |
|---|---|
| `docs/superpowers/specs/2026-09-21-nova-curriculum-design.md` | The design. The binding authority: read it first. |
| `docs/superpowers/plans/2026-09-21-nova-curriculum-spec.md` | The task-by-task plan that builds everything below. |
| `docs/curriculum/` | The eight explanatory chapters and the research log. |
| `data/` | The specification itself: `schema/` (JSON Schemas) plus YAML for skills, games, transfer tasks, evidence, parameters, assessment rules, language packs, mechanics, signals and i18n. |
| `tools/validate/` | The validator (Python) and its tests. |

## Run the validator

From `tools/validate`:

```bash
python -m venv .venv
.venv/Scripts/python.exe -m pip install -r requirements.txt
.venv/Scripts/python.exe -m pytest -q                  # the validator's own tests
.venv/Scripts/python.exe -m nova_validate --report     # validate ../../data
```

The data is valid only when the last command prints `0 error(s)`. See `tools/validate/README.md`.

## Ground rules for any agent working here

- **Work only inside this folder.** Do not create working copies or scratch files in temp or
  scratchpad directories; anything another agent needs must live in the project.
- The spec is the authority. Do not present any threshold or weight as validated: every
  parameter stays `provisional` until a linked calibration study exists.
- Evidence must be verified against the primary source before it is marked `verified: true`.
  Expert judgment and design inference are never recorded as empirical evidence.
- Engagement, completion and in-game performance are not evidence of learning or transfer.
- Every commit message ends with `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`.
