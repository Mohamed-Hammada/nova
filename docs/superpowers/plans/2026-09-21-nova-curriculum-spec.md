# Nova Curriculum Specification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Produce the Nova Master Curriculum Specification: a validated skill graph, game, assessment and language-pack dataset (YAML + JSON Schema) plus eight explanatory chapters, for ages 2-8, Arabic and English first.

**Architecture:** The data in `data/` is the specification. A small Python validator in `tools/validate/` enforces the spec's rules (evidence basis, transfer, parameters, coverage) so the dataset cannot drift. Tasks 1-9 build the validator test-first. Task 10 seeds the vocabularies and a worked example. Tasks 11-22 produce the research, the skill map, the deep clusters and the chapters, each gated by the validator.

**Tech Stack:** Python 3.11+ (tested on 3.14), PyYAML, jsonschema (Draft 2020-12), pytest. Markdown chapters. No app code.

**Spec:** `docs/superpowers/specs/2026-09-21-nova-curriculum-design.md` (revision 2.1 plus sync edits). Read it first; this plan implements it and argues from it.

## Global Constraints

Every task's requirements include this section. Values are copied from the spec.

- **Deliverable is the spec only.** No app code, UI, game engine, art/audio, backend or dashboard. The validator is spec tooling, not app code.
- **Skill graph is the source of truth.** Domains are tags. Age is an expected range, never a gate. Mastery states are exactly: Not yet -> Emerging -> Developing -> Secure -> Transfer.
- **Scope of depth.** Full skill map for ages 2-8, all 12 domains, at skill level. Deep coverage (mastery rules, difficulty ladders, assessment rules, game specs) for Executive Function, Memory, Math, Arabic literacy and English literacy at ages 3-6. A skill is in the deep set when it is in those domains and its `age_range` starts before 6 and ends after 3 (the validator enforces `deep_scope: true`).
- **Evidence type and strength are separate.** Type is a closed list of eight: `systematic_review`, `meta_analysis`, `rct`, `quasi_experimental`, `developmental_framework`, `program_evidence`, `expert_consensus`, `design_inference`. Strength is `emerging | moderate | strong`. Caps: `expert_consensus` at most `moderate`; `design_inference` at most `emerging`.
- **`evidence_basis` is deterministic:** precedence `empirical > framework > judgment`. Any empirical-class evidence gives `empirical`; otherwise any framework-class gives `framework`; otherwise `judgment`. A skill or game citing no evidence is an error.
- **Engagement, completion and within-game performance are not evidence of learning or transfer.** Every signal is tagged `learning` or `engagement`; assessment rules may consume only `learning` signals. In-game performance alone can never establish Secure or Transfer.
- **Transfer is its own assessment dimension.** A `cross_game` probe must use a different `mechanic_id` from the game that declares it, and its target must really use the mechanic it names. A reskin or new content on the same mechanic never counts. Every deep-scope skill is covered by at least two distinct `mechanic_id`s (two games, or one game plus a separately specified transfer task on a different mechanic) and has at least one valid `cross_game` probe.
- **Every parameter ships `provisional`.** No threshold, weight or cutoff is presented as scientifically validated. Nothing is `pilot_calibrated` or `validated` without a linked calibration study. Anything a parent sees that derives from a provisional parameter is labelled an estimate.
- **Claims are non-clinical.** Nova is "evidence-informed", never diagnostic, screening or clinical. "Evidence-based" may be used only for a skill or game with `evidence_basis: empirical` at strength `moderate` or stronger; otherwise "informed by".
- **Sources are verified.** The citations in the original brief are unverified and are not relied on. Every `verified: true` evidence entry was checked by opening the primary source. Unverifiable claims are dropped or recorded as `design_inference` / `expert_consensus` at the correct cap.
- **Arabic and English literacy are separate tracks,** with different progressions, not one translated into the other.
- **Every i18n key has a non-empty `en` and `ar` string.**
- **Commit trailer.** Every commit message ends with `Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>`. The plan writes this as a second `-m` argument.

---

## File Structure

```
D:\hamada\nova\
  .gitignore
  docs\superpowers\specs\2026-09-21-nova-curriculum-design.md   (exists)
  docs\superpowers\plans\2026-09-21-nova-curriculum-spec.md     (this file)
  docs\curriculum\
    01-research-foundation.md      programs matrix, evidence types/strength rubric, evidence table
    02-developmental-framework.md  domains, age stages, core principles, guided play
    03-skill-model.md              schemas explained: skill, mastery, difficulty, evidence
    04-assessment-adaptivity.md    assessment dimensions, transfer probes, signals, parameters
    05-language-packs.md           pack contract; Arabic + English tracks; zh/hi extension notes
    06-parent-reporting.md         what the dashboard may and may not claim
    07-safety-privacy-a11y.md      child data, content rules, accessibility
    08-validation-roadmap.md       educator review, pilot calibration plan, next sub-projects
    research-log.md                outcome of checking each pasted citation
  data\
    schema\*.schema.json           9 JSON Schemas (Task 2)
    mechanics.yaml  signals.yaml   controlled vocabularies (Task 10)
    langpacks\  evidence\  parameters\  skills\  games\  transfer_tasks\  assessment\  i18n\
  tools\validate\
    requirements.txt  pytest.ini
    nova_validate\                 model, loader, schema_rules, evidence_rules, graph_rules,
                                   parameter_rules, assessment_rules, game_rules,
                                   coverage_rules, langpack_rules, i18n_rules, report, cli
    tests\                         factory.py + one test file per rule module
```

Each rule module has one responsibility and is tested in isolation against `tests/factory.py`, which builds a small fully valid `Spec`. Every test copies it, breaks one thing, and asserts on the resulting issues.

## Conventions

**Running the validator** (from `D:\hamada\nova\tools\validate`, bash):

```bash
.venv/Scripts/python.exe -m pytest -q          # the validator's own tests
.venv/Scripts/python.exe -m nova_validate --report   # validate ../../data
```

Exit code is 0 when there are no errors. Warnings (for example a rung that changes two difficulty dimensions at once) do not fail the run but should be fixed unless there is a stated reason.

**Data layout and ids.** One list of records per YAML file; any file under a directory is loaded. Skills go in `data/skills/<domain>/<topic>.yaml`, games in `data/games/<domain>/<topic>.yaml`, and so on. Ids are lower-case with dots, for example `math.count.cardinality`, `game.math.bear-apples`, `task.math.count-objects-at-home`, `rule.math.count.cardinality`, `ev.design.counting-progression`, `param.default.min-trials`. Skill id prefixes used here: `math.`, `ef.`, `mem.`, `att.`, `lit.ar.`, `lit.en.`, `lang.oral.`, `cog.`, `ps.`, `vs.`, `fm.`, `soc.`, `cre.`, `sci.`.

**Worked examples.** Task 10 creates a complete, validator-checked counting slice (2 skills, 2 games, 1 transfer task, 2 assessment rules, 9 default parameters, evidence, i18n in English and Arabic). It is the template for every record type. Copy its shape exactly.

**Cluster procedure** (used by Tasks 13-17 and referred to as "Cluster procedure A-G"). For each deep cluster:

- **A. Skills.** Author every skill in the cluster table as a record, with `indicators` (2-4 observable behaviours, written as what a child does), `prerequisites` (edges from the table; add `evidence_refs` on an edge only when a verified source supports that ordering), `age_range` from the table, and `deep_scope` set as the rule in Global Constraints requires. Run the validator; it will name any skill that must be `deep_scope: true`.
- **B. Evidence.** For each skill, cite verified evidence from Task 11 where it exists (then `evidence_basis` follows the precedence rule). Where none exists, cite a `design_inference` entry you add to `data/evidence/design-inferences.yaml` (one entry per distinct assumption, honest `finding` and `limits`, `verified: false`, strength `emerging`). Never mark judgment as empirical.
- **C. i18n.** Add `name_key` and `description_key` strings in `data/i18n/en.yaml` and `data/i18n/ar.yaml` for every skill, game and transfer task. Arabic is written for children's Arabic, not machine-translated; leave it plain and correct.
- **D. Transfer tasks.** For each group of skills, author at least one transfer task with a mechanic that no game in the group uses, so that a `cross_game` probe is possible. Add a mechanic to `data/mechanics.yaml` only when the interaction genuinely differs from every existing one.
- **E. Games.** For each deep skill, author or reuse games so it has at least two distinct mechanics and a valid `cross_game` probe (see Global Constraints). Each game: `objective`, `mechanic_id` and `mechanic`; a ladder of at least 3 rungs that varies one dimension per step; an `anchors` label for every value each varied dimension takes; `scaffolding` (a hint and an adult prompt); `signals` including at least one learning signal and `error_type` where errors are diagnostic; `progression` using the default parameters; `transfer_probes`; an `offline_extension` where a physical version is natural; `language_dependencies`; and `evidence_basis` for the mechanic (usually `judgment`).
- **F. Assessment rules.** One rule per deep skill, using only learning signals, with all four state criteria and the required dimensions (emerging and developing: `performance`; secure: `performance` and `independence`; transfer: `transfer`). Use the `param.default.*` parameters. Add a skill-specific parameter to `data/parameters/<cluster>.yaml` only when a default is clearly wrong, and keep it `provisional`.
- **G. Gate and commit.** Run `python -m nova_validate --report`. It must print `0 error(s)`. Fix warnings or note why not. Commit.

---

## Phase 1: The validator (test-first)

### Task 1: Project scaffold, model and loader

**Files:**
- Create: `.gitignore`
- Create: `tools/validate/requirements.txt`, `tools/validate/pytest.ini`
- Create: `tools/validate/nova_validate/__init__.py`, `model.py`, `loader.py`
- Create: `tools/validate/tests/__init__.py`, `factory.py`, `test_loader.py`

**Interfaces:**
- Produces: `nova_validate.model` (`Spec`, `Issue`, `error()`, `warning()`, `index_by_id()`, and the constants `DOMAINS`, `DIFFICULTY_DIMENSIONS`, `SLOTS`, `MASTERY_STATES`, `ASSESSMENT_DIMENSIONS`, `EVIDENCE_TYPES`, `EVIDENCE_STRENGTHS`, `STRENGTH_RANK`, `STRENGTH_CAPS`, `DEEP_DOMAINS`, `DEEP_LANGUAGES`, `DEEP_AGE_WINDOW`); `nova_validate.loader.load_spec(data_root: Path) -> Spec`; `tests.factory.make_spec() -> Spec`, `get(records, id)`, `rules_of(issues)`, `errors_of(issues)`, `write_spec(spec, root)`.

- [ ] **Step 1: Create the config files and the virtual environment**

`.gitignore`:

```
.venv/
__pycache__/
.pytest_cache/
*.pyc
```

`tools/validate/requirements.txt`:

```
pyyaml>=6.0
jsonschema>=4.21
pytest>=8.0
```

`tools/validate/pytest.ini`:

```
[pytest]
pythonpath = .
testpaths = tests
```

`tools/validate/nova_validate/__init__.py`:

```python
"""Validator for the Nova curriculum specification data."""
```

`tools/validate/tests/__init__.py` is an empty file. Then set up the environment:

```bash
cd /d/hamada/nova/tools/validate
python -m venv .venv
.venv/Scripts/python.exe -m pip install -r requirements.txt
```

- [ ] **Step 2: Write the tests and the fixture factory**

`tools/validate/tests/factory.py`:

```python
"""A small, fully valid Spec used as the baseline by every rule test.

Tests call make_spec(), mutate one thing, and assert on the resulting issues.
The ids and strings here are fixtures only; they are not curriculum content.
"""
from __future__ import annotations

from pathlib import Path

import yaml

from nova_validate.model import DIFFICULTY_DIMENSIONS, Issue, Record, Spec


def get(records: list[Record], record_id: str) -> Record:
    for record in records:
        if record["id"] == record_id:
            return record
    raise KeyError(record_id)


def rules_of(issues: list[Issue]) -> set[str]:
    return {issue.rule for issue in issues}


def errors_of(issues: list[Issue]) -> list[Issue]:
    return [issue for issue in issues if issue.level == "error"]


def _rung(rung_id: str, **values: int) -> Record:
    full = {dimension: 0 for dimension in DIFFICULTY_DIMENSIONS}
    full.update(values)
    return {"id": rung_id, "values": full}


def _criteria() -> Record:
    def criterion(description: str, dimensions: list[str]) -> Record:
        return {
            "description": description,
            "parameters": ["param.test.secure-accuracy"],
            "requires_dimensions": dimensions,
        }

    return {
        "emerging": criterion("Some correct responses with heavy support", ["performance"]),
        "developing": criterion("Mostly correct with hints", ["performance"]),
        "secure": criterion("Correct with little or no support", ["performance", "independence"]),
        "transfer": criterion("Passes a cross-game or cross-context probe", ["transfer"]),
    }


def _rule(rule_id: str, skill_id: str) -> Record:
    return {
        "id": rule_id,
        "skill": skill_id,
        "inputs": ["accuracy", "hints_used"],
        "state_criteria": _criteria(),
    }


def _probe(probe_id: str, kind: str, skill: str, mechanic: str, task_ref: str, delayed: bool = False) -> Record:
    return {
        "id": probe_id,
        "type": kind,
        "delayed": delayed,
        "skill": skill,
        "mechanic_id": mechanic,
        "task_ref": task_ref,
        "changes": "Surface and setting change",
        "preserved": "The underlying skill demand",
    }


def _parameter(param_id: str, value: float) -> Record:
    return {
        "id": param_id,
        "value": value,
        "unit": "proportion",
        "status": "provisional",
        "basis": "design_inference",
        "rationale": "Starting point chosen by design; not a finding.",
        "calibration_plan": "Set from pilot data on at least 100 children.",
    }


def _evidence(ev_id: str, kind: str, strength: str, verified: bool) -> Record:
    return {
        "id": ev_id,
        "title": f"Fixture evidence {ev_id}",
        "citation": "Fixture citation",
        "verified": verified,
        "evidence_type": kind,
        "evidence_strength": strength,
        "population": "children 3-6 years",
        "delivery": "mixed",
        "language": "en",
        "finding": "Fixture finding.",
        "limits": "Fixture limits.",
    }


def make_spec() -> Spec:
    skills: list[Record] = [
        {
            "id": "math.count.one-to-one-5",
            "domains": ["math"],
            "name_key": "skill.math.count.one-to-one-5.name",
            "description_key": "skill.math.count.one-to-one-5.description",
            "prerequisites": [],
            "age_range": [3, 4],
            "indicators": ["Touches each object once while counting up to 5"],
            "evidence_basis": "judgment",
            "evidence_refs": ["ev.test.design"],
            "scope": "universal",
            "deep_scope": True,
        },
        {
            "id": "math.count.cardinality",
            "domains": ["math"],
            "name_key": "skill.math.count.cardinality.name",
            "description_key": "skill.math.count.cardinality.description",
            "prerequisites": [{"skill": "math.count.one-to-one-5"}],
            "age_range": [4, 5],
            "indicators": ["States the last number counted as the total"],
            "evidence_basis": "empirical",
            "evidence_refs": ["ev.test.meta"],
            "scope": "universal",
            "deep_scope": True,
        },
        {
            "id": "lit.ar.letter.recognize-isolated",
            "domains": ["language_literacy"],
            "name_key": "skill.lit.ar.letter.recognize-isolated.name",
            "description_key": "skill.lit.ar.letter.recognize-isolated.description",
            "prerequisites": [],
            "age_range": [4, 5],
            "indicators": ["Picks the named letter from a group of isolated letters"],
            "evidence_basis": "framework",
            "evidence_refs": ["ev.test.framework"],
            "scope": "language-specific",
            "language": "ar",
            "slot": "letter_knowledge",
            "deep_scope": True,
        },
        {
            "id": "soc.emotion.name-basic",
            "domains": ["social_emotional"],
            "name_key": "skill.soc.emotion.name-basic.name",
            "description_key": "skill.soc.emotion.name-basic.description",
            "prerequisites": [],
            "age_range": [3, 5],
            "indicators": ["Names happy, sad, angry and scared from pictures"],
            "evidence_basis": "framework",
            "evidence_refs": ["ev.test.framework"],
            "scope": "universal",
            "deep_scope": False,
        },
    ]

    games: list[Record] = [
        {
            "id": "game.math.bear-snacks",
            "name_key": "game.math.bear-snacks.name",
            "age_range": [4, 5],
            "primary_skills": ["math.count.one-to-one-5", "math.count.cardinality"],
            "secondary_skills": [],
            "objective": "Give the bear exactly the number of apples it asks for",
            "mechanic_id": "drag-to-count",
            "mechanic": "The child drags apples onto a plate while the bear asks for a number",
            "evidence_basis": "judgment",
            "evidence_refs": ["ev.test.design"],
            "difficulty": {
                "varied": ["item_complexity", "distractors"],
                "anchors": {
                    "item_complexity": ["quantities 1 to 3", "quantities 1 to 5"],
                    "distractors": ["no extra objects", "extra objects on the table"],
                },
                "rungs": [
                    _rung("r1"),
                    _rung("r2", item_complexity=1),
                    _rung("r3", item_complexity=1, distractors=1),
                ],
            },
            "scaffolding": {
                "hints": ["The bear points at the plate"],
                "adult_prompt": "Ask: how many apples does the bear have now?",
            },
            "signals": ["accuracy", "hints_used", "completion"],
            "progression": {
                "advance_parameter": "param.test.advance",
                "retreat_parameter": "param.test.retreat",
            },
            "transfer_probes": [
                _probe("probe.one-to-one", "cross_game", "math.count.one-to-one-5", "physical-counting", "task.math.count-objects-at-home"),
                _probe("probe.cardinality", "cross_game", "math.count.cardinality", "physical-counting", "task.math.count-objects-at-home"),
                _probe("probe.cardinality-later", "cross_context", "math.count.cardinality", "physical-counting", "task.math.count-objects-at-home", delayed=True),
            ],
            "language_dependencies": [],
        },
        {
            "id": "game.math.number-match",
            "name_key": "game.math.number-match.name",
            "age_range": [4, 5],
            "primary_skills": ["math.count.cardinality"],
            "secondary_skills": [],
            "objective": "Match a numeral card to the group with that many items",
            "mechanic_id": "match-symbol-to-quantity",
            "mechanic": "The child pairs a numeral with the matching group of objects",
            "evidence_basis": "judgment",
            "evidence_refs": ["ev.test.design"],
            "difficulty": {
                "varied": ["abstraction", "distractors"],
                "anchors": {
                    "abstraction": ["dot pictures", "numerals"],
                    "distractors": ["two groups", "three groups"],
                },
                "rungs": [
                    _rung("r1"),
                    _rung("r2", abstraction=1),
                    _rung("r3", abstraction=1, distractors=1),
                ],
            },
            "scaffolding": {
                "hints": ["Highlight one group at a time"],
                "adult_prompt": "Ask the child to count the group out loud.",
            },
            "signals": ["accuracy", "response_time"],
            "progression": {
                "advance_parameter": "param.test.advance",
                "retreat_parameter": "param.test.retreat",
            },
            "transfer_probes": [],
            "language_dependencies": [],
        },
        {
            "id": "game.lit.ar.letter-catch",
            "name_key": "game.lit.ar.letter-catch.name",
            "age_range": [4, 5],
            "primary_skills": ["lit.ar.letter.recognize-isolated"],
            "secondary_skills": [],
            "objective": "Catch the falling letter that matches the spoken letter name",
            "mechanic_id": "catch-target",
            "mechanic": "Letters fall; the child taps the one that matches the spoken name",
            "evidence_basis": "judgment",
            "evidence_refs": ["ev.test.design"],
            "difficulty": {
                "varied": ["distractors", "cognitive_load"],
                "anchors": {
                    "distractors": ["two letters", "four letters"],
                    "cognitive_load": ["untimed", "gentle time pressure"],
                },
                "rungs": [
                    _rung("r1"),
                    _rung("r2", distractors=1),
                    _rung("r3", distractors=1, cognitive_load=1),
                ],
            },
            "scaffolding": {
                "hints": ["The target letter glows briefly"],
                "adult_prompt": "Say the letter name together, then point to it on a card.",
            },
            "signals": ["accuracy", "response_time", "error_type"],
            "progression": {
                "advance_parameter": "param.test.advance",
                "retreat_parameter": "param.test.retreat",
            },
            "transfer_probes": [
                _probe("probe.letter-in-print", "cross_game", "lit.ar.letter.recognize-isolated", "print-hunt", "task.lit.ar.find-letter-in-print"),
            ],
            "language_dependencies": ["ar"],
        },
    ]

    transfer_tasks: list[Record] = [
        {
            "id": "task.math.count-objects-at-home",
            "name_key": "task.math.count-objects-at-home.name",
            "age_range": [4, 5],
            "skills": ["math.count.one-to-one-5", "math.count.cardinality"],
            "mechanic_id": "physical-counting",
            "description": "The child counts real household objects an adult names",
            "signals": ["accuracy", "hints_used"],
            "scoring": "Adult marks each count correct or incorrect in the app",
        },
        {
            "id": "task.lit.ar.find-letter-in-print",
            "name_key": "task.lit.ar.find-letter-in-print.name",
            "age_range": [4, 5],
            "skills": ["lit.ar.letter.recognize-isolated"],
            "mechanic_id": "print-hunt",
            "description": "The child finds a named letter on a printed page or sign",
            "signals": ["accuracy"],
            "scoring": "Adult marks the letter found or not found",
        },
    ]

    evidence: list[Record] = [
        _evidence("ev.test.design", "design_inference", "emerging", verified=False),
        _evidence("ev.test.meta", "meta_analysis", "moderate", verified=True),
        _evidence("ev.test.framework", "developmental_framework", "moderate", verified=True),
    ]

    parameters: list[Record] = [
        _parameter("param.test.advance", 0.8),
        _parameter("param.test.retreat", 0.5),
        _parameter("param.test.secure-accuracy", 0.85),
    ]

    assessment_rules: list[Record] = [
        _rule("rule.math.count.one-to-one-5", "math.count.one-to-one-5"),
        _rule("rule.math.count.cardinality", "math.count.cardinality"),
        _rule("rule.lit.ar.letter.recognize-isolated", "lit.ar.letter.recognize-isolated"),
    ]

    langpacks: list[Record] = [
        {
            "id": "ar",
            "name": "Arabic",
            "status": "in_progress",
            "script": {"direction": "rtl", "joining": True, "diacritics": True, "tonal": False, "notes": "Letters take initial, medial, final and isolated forms."},
            "slots_filled": ["letter_knowledge"],
            "instruction_voice": "undecided",
        },
        {
            "id": "zh",
            "name": "Chinese",
            "status": "contract_only",
            "script": {"direction": "ltr", "joining": False, "diacritics": False, "tonal": True, "notes": "Logographic; pinyin and tones."},
            "slots_filled": [],
            "instruction_voice": "undecided",
        },
    ]

    mechanics: list[Record] = [
        {"id": mechanic, "description": f"Fixture mechanic {mechanic}"}
        for mechanic in ("drag-to-count", "match-symbol-to-quantity", "physical-counting", "catch-target", "print-hunt")
    ]

    signals: list[Record] = [
        {"id": "accuracy", "kind": "learning", "description": "Share of responses that are correct"},
        {"id": "response_time", "kind": "learning", "description": "Time to respond"},
        {"id": "hints_used", "kind": "learning", "description": "Number of hints requested or shown"},
        {"id": "error_type", "kind": "learning", "description": "Category of each error"},
        {"id": "session_time", "kind": "engagement", "description": "Minutes spent in the app"},
        {"id": "completion", "kind": "engagement", "description": "Whether the level was finished"},
    ]

    keys = [skill[key] for skill in skills for key in ("name_key", "description_key")]
    keys += [game["name_key"] for game in games]
    keys += [task["name_key"] for task in transfer_tasks]
    i18n = {
        "en": {key: f"English text for {key}" for key in keys},
        "ar": {key: f"نص عربي لـ {key}" for key in keys},
    }

    return Spec(
        skills=skills,
        games=games,
        transfer_tasks=transfer_tasks,
        evidence=evidence,
        parameters=parameters,
        assessment_rules=assessment_rules,
        langpacks=langpacks,
        mechanics=mechanics,
        signals=signals,
        i18n=i18n,
    )


def write_spec(spec: Spec, root: Path) -> None:
    """Write a Spec to disk in the layout that load_spec reads."""

    def dump(path: Path, data) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(yaml.safe_dump(data, allow_unicode=True, sort_keys=False), encoding="utf-8")

    dump(root / "skills" / "skills.yaml", spec.skills)
    dump(root / "games" / "games.yaml", spec.games)
    dump(root / "transfer_tasks" / "tasks.yaml", spec.transfer_tasks)
    dump(root / "evidence" / "evidence.yaml", spec.evidence)
    dump(root / "parameters" / "parameters.yaml", spec.parameters)
    dump(root / "assessment" / "rules.yaml", spec.assessment_rules)
    dump(root / "langpacks" / "langpacks.yaml", spec.langpacks)
    dump(root / "mechanics.yaml", spec.mechanics)
    dump(root / "signals.yaml", spec.signals)
    for language, table in spec.i18n.items():
        dump(root / "i18n" / f"{language}.yaml", table)
```

`tools/validate/tests/test_loader.py`:

```python
import pytest

from nova_validate.loader import load_spec
from tests.factory import get, make_spec, write_spec


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def test_loads_records_from_nested_directories(tmp_path):
    write(tmp_path / "skills" / "a.yaml", "- id: a.one\n- id: a.two\n")
    write(tmp_path / "skills" / "deep" / "b.yaml", "- id: b.one\n")
    spec = load_spec(tmp_path)
    assert sorted(skill["id"] for skill in spec.skills) == ["a.one", "a.two", "b.one"]


def test_loads_vocabulary_files_and_i18n(tmp_path):
    write(tmp_path / "mechanics.yaml", "- id: sort-by-rule\n  description: Sort items\n")
    write(tmp_path / "i18n" / "en.yaml", "skill.a.name: Counting\n")
    spec = load_spec(tmp_path)
    assert spec.mechanics[0]["id"] == "sort-by-rule"
    assert spec.i18n["en"]["skill.a.name"] == "Counting"
    assert spec.i18n["ar"] == {}


def test_missing_directories_yield_empty_collections(tmp_path):
    spec = load_spec(tmp_path)
    assert spec.skills == [] and spec.games == [] and spec.langpacks == []
    assert spec.mechanics == [] and spec.signals == []


def test_non_list_file_is_rejected(tmp_path):
    write(tmp_path / "skills" / "bad.yaml", "id: not-a-list\n")
    with pytest.raises(ValueError, match="top level"):
        load_spec(tmp_path)


def test_non_mapping_item_is_rejected(tmp_path):
    write(tmp_path / "skills" / "bad.yaml", "- just a string\n")
    with pytest.raises(ValueError, match="not a mapping"):
        load_spec(tmp_path)


def test_reads_utf8_arabic(tmp_path):
    write(tmp_path / "i18n" / "ar.yaml", "skill.a.name: العد\n")
    assert load_spec(tmp_path).i18n["ar"]["skill.a.name"] == "العد"


def test_factory_specs_are_independent():
    first, second = make_spec(), make_spec()
    first.skills[0]["indicators"].append("changed")
    assert second.skills[0]["indicators"] == ["Touches each object once while counting up to 5"]


def test_factory_spec_round_trips_through_disk(tmp_path):
    original = make_spec()
    write_spec(original, tmp_path)
    loaded = load_spec(tmp_path)
    assert loaded.skills == original.skills
    assert loaded.games == original.games
    assert get(loaded.langpacks, "ar")["script"]["direction"] == "rtl"
    assert loaded.i18n == original.i18n
```

- [ ] **Step 3: Run the tests to verify they fail**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: collection error, `ModuleNotFoundError: No module named 'nova_validate.loader'`.

- [ ] **Step 4: Implement the model and loader**

`tools/validate/nova_validate/model.py`:

```python
"""Shared types and constants for the Nova spec validator."""
from __future__ import annotations

from dataclasses import dataclass, field
from typing import Any

Record = dict[str, Any]

DOMAINS = (
    "cognitive",
    "executive_function",
    "language_literacy",
    "math",
    "problem_solving",
    "memory",
    "attention",
    "visual_spatial",
    "fine_motor",
    "social_emotional",
    "creativity",
    "science_exploration",
)

# The seven difficulty dimensions (spec 3.3).
DIFFICULTY_DIMENSIONS = (
    "item_complexity",
    "distractors",
    "working_memory_load",
    "rule_complexity",
    "abstraction",
    "cognitive_load",
    "independence",
)

# Shared literacy slots that every language pack fills (spec 3.8).
SLOTS = (
    "listening",
    "vocabulary",
    "phonological_awareness",
    "print_concepts",
    "letter_knowledge",
    "sound_mapping",
    "word_building",
    "early_reading",
)

MASTERY_STATES = ("emerging", "developing", "secure", "transfer")

# Assessment dimensions that a mastery state can require (spec 3.4).
ASSESSMENT_DIMENSIONS = ("performance", "independence", "transfer")

# Evidence type -> evidence class (spec 3.6).
EVIDENCE_TYPES = {
    "systematic_review": "empirical",
    "meta_analysis": "empirical",
    "rct": "empirical",
    "quasi_experimental": "empirical",
    "developmental_framework": "framework",
    "program_evidence": "framework",
    "expert_consensus": "judgment",
    "design_inference": "judgment",
}

EVIDENCE_STRENGTHS = ("emerging", "moderate", "strong")
STRENGTH_RANK = {name: rank for rank, name in enumerate(EVIDENCE_STRENGTHS, start=1)}

# Judgment-class evidence can never be rated above these caps.
STRENGTH_CAPS = {"expert_consensus": "moderate", "design_inference": "emerging"}

# Deep-coverage set (spec 3.1): these domains, plus Arabic and English literacy,
# for skills whose age range starts before DEEP_AGE_WINDOW[1] and ends after [0].
DEEP_DOMAINS = frozenset({"executive_function", "memory", "math"})
DEEP_LANGUAGES = frozenset({"ar", "en"})
DEEP_AGE_WINDOW = (3, 6)


@dataclass(frozen=True)
class Issue:
    level: str  # "error" | "warning"
    rule: str
    where: str
    message: str

    def __str__(self) -> str:
        return f"{self.level.upper()} [{self.rule}] {self.where}: {self.message}"


def error(rule: str, where: str, message: str) -> Issue:
    return Issue("error", rule, where, message)


def warning(rule: str, where: str, message: str) -> Issue:
    return Issue("warning", rule, where, message)


@dataclass
class Spec:
    skills: list[Record] = field(default_factory=list)
    games: list[Record] = field(default_factory=list)
    transfer_tasks: list[Record] = field(default_factory=list)
    evidence: list[Record] = field(default_factory=list)
    parameters: list[Record] = field(default_factory=list)
    assessment_rules: list[Record] = field(default_factory=list)
    langpacks: list[Record] = field(default_factory=list)
    mechanics: list[Record] = field(default_factory=list)
    signals: list[Record] = field(default_factory=list)
    i18n: dict[str, dict[str, str]] = field(default_factory=dict)


def index_by_id(records: list[Record]) -> dict[str, Record]:
    return {record["id"]: record for record in records}
```

`tools/validate/nova_validate/loader.py`:

```python
"""Load the YAML spec data from disk into a Spec."""
from __future__ import annotations

from pathlib import Path

import yaml

from .model import Record, Spec

# Spec attribute -> subdirectory of the data root (every *.yaml below it is a list of records).
RECORD_DIRS = {
    "skills": "skills",
    "games": "games",
    "transfer_tasks": "transfer_tasks",
    "evidence": "evidence",
    "parameters": "parameters",
    "assessment_rules": "assessment",
    "langpacks": "langpacks",
}

# Spec attribute -> single file at the data root (a list of records).
RECORD_FILES = {
    "mechanics": "mechanics.yaml",
    "signals": "signals.yaml",
}

I18N_LANGUAGES = ("en", "ar")


def _read_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def _load_list(path: Path) -> list[Record]:
    data = _read_yaml(path)
    if data is None:
        return []
    if not isinstance(data, list):
        raise ValueError(f"{path}: top level must be a YAML list of records")
    for index, item in enumerate(data):
        if not isinstance(item, dict):
            raise ValueError(f"{path}: item {index} is not a mapping")
    return data


def _load_dir(directory: Path) -> list[Record]:
    records: list[Record] = []
    if directory.is_dir():
        for path in sorted(directory.rglob("*.yaml")):
            records.extend(_load_list(path))
    return records


def _load_i18n(directory: Path) -> dict[str, dict[str, str]]:
    table: dict[str, dict[str, str]] = {}
    for language in I18N_LANGUAGES:
        path = directory / f"{language}.yaml"
        data = _read_yaml(path) if path.is_file() else None
        if data is not None and not isinstance(data, dict):
            raise ValueError(f"{path}: must be a flat YAML mapping of key -> string")
        table[language] = data or {}
    return table


def load_spec(data_root: Path) -> Spec:
    root = Path(data_root)
    fields: dict[str, list[Record]] = {
        attr: _load_dir(root / subdir) for attr, subdir in RECORD_DIRS.items()
    }
    for attr, filename in RECORD_FILES.items():
        path = root / filename
        fields[attr] = _load_list(path) if path.is_file() else []
    return Spec(i18n=_load_i18n(root / "i18n"), **fields)
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `8 passed`.

- [ ] **Step 6: Commit**

```bash
cd /d/hamada/nova
git add .gitignore tools/validate
git commit -m "Add validator scaffold, model and loader" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 2: JSON Schemas and structural checks

**Files:**
- Create: `data/schema/skill.schema.json`, `game.schema.json`, `transfer_task.schema.json`, `evidence.schema.json`, `parameter.schema.json`, `assessment_rule.schema.json`, `langpack.schema.json`, `mechanic.schema.json`, `signal.schema.json`
- Create: `tools/validate/nova_validate/schema_rules.py`
- Test: `tools/validate/tests/test_schema_rules.py`

**Interfaces:**
- Consumes: `Spec`, `Issue`, `error` from Task 1; `make_spec`, `get`, `rules_of` from `tests.factory`.
- Produces: `schema_rules.SCHEMA_FILES: dict[str, str]`, `load_schema(schema_dir, filename) -> dict`, `check_schemas(spec, schema_dir) -> list[Issue]` (rule `schema`), `check_unique_ids(spec) -> list[Issue]` (rule `unique-id`).

- [ ] **Step 1: Write the failing test**

`tools/validate/tests/test_schema_rules.py`:

```python
from pathlib import Path

from nova_validate import model
from nova_validate.schema_rules import SCHEMA_FILES, check_schemas, check_unique_ids, load_schema
from tests.factory import get, make_spec, rules_of

SCHEMA_DIR = Path(__file__).resolve().parents[3] / "data" / "schema"


def messages(issues):
    return " | ".join(issue.message for issue in issues)


def test_valid_factory_spec_passes_schemas():
    assert check_schemas(make_spec(), SCHEMA_DIR) == []


def test_missing_required_field_is_reported():
    spec = make_spec()
    del spec.skills[0]["indicators"]
    issues = check_schemas(spec, SCHEMA_DIR)
    assert rules_of(issues) == {"schema"}
    assert "indicators" in messages(issues)


def test_unknown_property_is_rejected():
    spec = make_spec()
    spec.skills[0]["surprise"] = 1
    assert "surprise" in messages(check_schemas(spec, SCHEMA_DIR))


def test_unknown_domain_is_rejected():
    spec = make_spec()
    spec.skills[0]["domains"] = ["astrology"]
    assert check_schemas(spec, SCHEMA_DIR)


def test_language_specific_skill_requires_language():
    spec = make_spec()
    del get(spec.skills, "lit.ar.letter.recognize-isolated")["language"]
    assert "language" in messages(check_schemas(spec, SCHEMA_DIR))


def test_universal_skill_rejects_language_and_slot():
    spec = make_spec()
    spec.skills[0]["language"] = "ar"
    assert check_schemas(spec, SCHEMA_DIR)


def test_rung_must_define_every_difficulty_dimension():
    spec = make_spec()
    del spec.games[0]["difficulty"]["rungs"][0]["values"]["abstraction"]
    assert "abstraction" in messages(check_schemas(spec, SCHEMA_DIR))


def test_assessment_rule_needs_all_four_states():
    spec = make_spec()
    del spec.assessment_rules[0]["state_criteria"]["transfer"]
    assert "transfer" in messages(check_schemas(spec, SCHEMA_DIR))


def test_duplicate_ids_are_reported():
    spec = make_spec()
    spec.skills.append(dict(spec.skills[0]))
    issues = check_unique_ids(spec)
    assert rules_of(issues) == {"unique-id"}
    assert "math.count.one-to-one-5" in issues[0].where


def _enum(schema, *path):
    node = schema
    for part in path:
        node = node[part]
    return sorted(node)


def test_schema_enums_match_model_constants():
    load = lambda name: load_schema(SCHEMA_DIR, SCHEMA_FILES[name])
    skill, game, evidence = load("skills"), load("games"), load("evidence")
    rule, langpack = load("assessment_rules"), load("langpacks")

    assert _enum(skill, "properties", "domains", "items", "enum") == sorted(model.DOMAINS)
    assert _enum(skill, "properties", "slot", "enum") == sorted(model.SLOTS)
    assert _enum(langpack, "properties", "slots_filled", "items", "enum") == sorted(model.SLOTS)
    assert _enum(game, "properties", "difficulty", "properties", "varied", "items", "enum") == sorted(model.DIFFICULTY_DIMENSIONS)
    rung_values = game["properties"]["difficulty"]["properties"]["rungs"]["items"]["properties"]["values"]
    assert sorted(rung_values["required"]) == sorted(model.DIFFICULTY_DIMENSIONS)
    assert sorted(rung_values["properties"]) == sorted(model.DIFFICULTY_DIMENSIONS)
    assert _enum(evidence, "properties", "evidence_type", "enum") == sorted(model.EVIDENCE_TYPES)
    assert _enum(evidence, "properties", "evidence_strength", "enum") == sorted(model.EVIDENCE_STRENGTHS)
    assert _enum(rule, "$defs", "criterion", "properties", "requires_dimensions", "items", "enum") == sorted(model.ASSESSMENT_DIMENSIONS)
    assert sorted(rule["properties"]["state_criteria"]["required"]) == sorted(model.MASTERY_STATES)
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/Scripts/python.exe -m pytest tests/test_schema_rules.py -q`
Expected: collection error, `ModuleNotFoundError: No module named 'nova_validate.schema_rules'`.

- [ ] **Step 3: Write the schemas**

`data/schema/skill.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Skill node",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id", "domains", "name_key", "description_key", "prerequisites", "age_range",
    "indicators", "evidence_basis", "evidence_refs", "scope", "deep_scope"
  ],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z0-9_]+(\\.[a-z0-9_-]+)+$" },
    "domains": {
      "type": "array",
      "minItems": 1,
      "uniqueItems": true,
      "items": {
        "enum": [
          "cognitive", "executive_function", "language_literacy", "math",
          "problem_solving", "memory", "attention", "visual_spatial",
          "fine_motor", "social_emotional", "creativity", "science_exploration"
        ]
      }
    },
    "name_key": { "type": "string", "minLength": 1 },
    "description_key": { "type": "string", "minLength": 1 },
    "prerequisites": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["skill"],
        "properties": {
          "skill": { "type": "string" },
          "evidence_refs": { "type": "array", "items": { "type": "string" } }
        }
      }
    },
    "age_range": {
      "type": "array",
      "minItems": 2,
      "maxItems": 2,
      "items": { "type": "number", "minimum": 2, "maximum": 8 }
    },
    "indicators": {
      "type": "array",
      "minItems": 1,
      "items": { "type": "string", "minLength": 1 }
    },
    "evidence_basis": { "enum": ["empirical", "framework", "judgment"] },
    "evidence_refs": { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "scope": { "enum": ["universal", "language-specific"] },
    "language": { "type": "string", "pattern": "^[a-z]{2,3}$" },
    "slot": {
      "enum": [
        "listening", "vocabulary", "phonological_awareness", "print_concepts",
        "letter_knowledge", "sound_mapping", "word_building", "early_reading"
      ]
    },
    "deep_scope": { "type": "boolean" }
  },
  "allOf": [
    {
      "if": { "properties": { "scope": { "const": "language-specific" } }, "required": ["scope"] },
      "then": { "required": ["language"] }
    },
    {
      "if": { "properties": { "scope": { "const": "universal" } }, "required": ["scope"] },
      "then": { "not": { "anyOf": [{ "required": ["language"] }, { "required": ["slot"] }] } }
    }
  ]
}
```

`data/schema/game.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Game spec",
  "type": "object",
  "$defs": {
    "anchor_labels": {
      "type": "array",
      "minItems": 1,
      "items": { "type": "string", "minLength": 1 }
    }
  },
  "additionalProperties": false,
  "required": [
    "id", "name_key", "age_range", "primary_skills", "secondary_skills", "objective",
    "mechanic_id", "mechanic", "evidence_basis", "evidence_refs", "difficulty",
    "scaffolding", "signals", "progression", "transfer_probes", "language_dependencies"
  ],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z0-9_]+(\\.[a-z0-9_-]+)+$" },
    "name_key": { "type": "string", "minLength": 1 },
    "age_range": {
      "type": "array",
      "minItems": 2,
      "maxItems": 2,
      "items": { "type": "number", "minimum": 2, "maximum": 8 }
    },
    "primary_skills": { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "secondary_skills": { "type": "array", "items": { "type": "string" } },
    "objective": { "type": "string", "minLength": 1 },
    "mechanic_id": { "type": "string", "pattern": "^[a-z0-9_-]+$" },
    "mechanic": { "type": "string", "minLength": 1 },
    "evidence_basis": { "enum": ["empirical", "framework", "judgment"] },
    "evidence_refs": { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "difficulty": {
      "type": "object",
      "additionalProperties": false,
      "required": ["varied", "anchors", "rungs"],
      "properties": {
        "anchors": {
          "type": "object",
          "additionalProperties": false,
          "properties": {
            "item_complexity": { "$ref": "#/$defs/anchor_labels" },
            "distractors": { "$ref": "#/$defs/anchor_labels" },
            "working_memory_load": { "$ref": "#/$defs/anchor_labels" },
            "rule_complexity": { "$ref": "#/$defs/anchor_labels" },
            "abstraction": { "$ref": "#/$defs/anchor_labels" },
            "cognitive_load": { "$ref": "#/$defs/anchor_labels" },
            "independence": { "$ref": "#/$defs/anchor_labels" }
          }
        },
        "varied": {
          "type": "array",
          "minItems": 1,
          "uniqueItems": true,
          "items": {
            "enum": [
              "item_complexity", "distractors", "working_memory_load", "rule_complexity",
              "abstraction", "cognitive_load", "independence"
            ]
          }
        },
        "rungs": {
          "type": "array",
          "minItems": 2,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": ["id", "values"],
            "properties": {
              "id": { "type": "string", "minLength": 1 },
              "values": {
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "item_complexity", "distractors", "working_memory_load", "rule_complexity",
                  "abstraction", "cognitive_load", "independence"
                ],
                "properties": {
                  "item_complexity": { "type": "integer", "minimum": 0 },
                  "distractors": { "type": "integer", "minimum": 0 },
                  "working_memory_load": { "type": "integer", "minimum": 0 },
                  "rule_complexity": { "type": "integer", "minimum": 0 },
                  "abstraction": { "type": "integer", "minimum": 0 },
                  "cognitive_load": { "type": "integer", "minimum": 0 },
                  "independence": { "type": "integer", "minimum": 0 }
                }
              }
            }
          }
        }
      }
    },
    "scaffolding": {
      "type": "object",
      "additionalProperties": false,
      "required": ["hints", "adult_prompt"],
      "properties": {
        "hints": { "type": "array", "minItems": 1, "items": { "type": "string", "minLength": 1 } },
        "adult_prompt": { "type": "string", "minLength": 1 }
      }
    },
    "signals": { "type": "array", "minItems": 1, "uniqueItems": true, "items": { "type": "string" } },
    "progression": {
      "type": "object",
      "additionalProperties": false,
      "required": ["advance_parameter", "retreat_parameter"],
      "properties": {
        "advance_parameter": { "type": "string" },
        "retreat_parameter": { "type": "string" }
      }
    },
    "transfer_probes": {
      "type": "array",
      "items": {
        "type": "object",
        "additionalProperties": false,
        "required": ["id", "type", "delayed", "skill", "mechanic_id", "task_ref", "changes", "preserved"],
        "properties": {
          "id": { "type": "string", "minLength": 1 },
          "type": { "enum": ["cross_game", "cross_context"] },
          "delayed": { "type": "boolean" },
          "skill": { "type": "string" },
          "mechanic_id": { "type": "string", "pattern": "^[a-z0-9_-]+$" },
          "task_ref": { "type": "string" },
          "changes": { "type": "string", "minLength": 1 },
          "preserved": { "type": "string", "minLength": 1 }
        }
      }
    },
    "offline_extension": { "type": "string", "minLength": 1 },
    "language_dependencies": {
      "type": "array",
      "uniqueItems": true,
      "items": { "type": "string", "pattern": "^[a-z]{2,3}$" }
    }
  }
}
```

`data/schema/transfer_task.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Transfer task",
  "type": "object",
  "additionalProperties": false,
  "required": ["id", "name_key", "age_range", "skills", "mechanic_id", "description", "signals", "scoring"],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z0-9_]+(\\.[a-z0-9_-]+)+$" },
    "name_key": { "type": "string", "minLength": 1 },
    "age_range": {
      "type": "array",
      "minItems": 2,
      "maxItems": 2,
      "items": { "type": "number", "minimum": 2, "maximum": 8 }
    },
    "skills": { "type": "array", "minItems": 1, "items": { "type": "string" } },
    "mechanic_id": { "type": "string", "pattern": "^[a-z0-9_-]+$" },
    "description": { "type": "string", "minLength": 1 },
    "signals": { "type": "array", "minItems": 1, "uniqueItems": true, "items": { "type": "string" } },
    "scoring": { "type": "string", "minLength": 1 }
  }
}
```

`data/schema/evidence.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Evidence entry",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "id", "title", "citation", "verified", "evidence_type", "evidence_strength",
    "population", "delivery", "language", "finding", "limits"
  ],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z0-9_]+(\\.[a-z0-9_-]+)+$" },
    "title": { "type": "string", "minLength": 1 },
    "citation": { "type": "string", "minLength": 1 },
    "url": { "type": "string", "minLength": 1 },
    "verified": { "type": "boolean" },
    "evidence_type": {
      "enum": [
        "systematic_review", "meta_analysis", "rct", "quasi_experimental",
        "developmental_framework", "program_evidence", "expert_consensus", "design_inference"
      ]
    },
    "evidence_strength": { "enum": ["emerging", "moderate", "strong"] },
    "population": { "type": "string", "minLength": 1 },
    "delivery": { "enum": ["teacher_led", "digital", "mixed", "home", "not_applicable"] },
    "language": { "type": "string", "minLength": 1 },
    "finding": { "type": "string", "minLength": 1 },
    "limits": { "type": "string", "minLength": 1 }
  }
}
```

`data/schema/parameter.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Calibration parameter",
  "type": "object",
  "additionalProperties": false,
  "required": ["id", "value", "unit", "status", "basis", "rationale", "calibration_plan"],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z0-9_]+(\\.[a-z0-9_-]+)+$" },
    "value": { "type": ["number", "string", "boolean"] },
    "unit": { "type": "string", "minLength": 1 },
    "status": { "enum": ["provisional", "pilot_calibrated", "validated"] },
    "basis": { "enum": ["design_inference", "borrowed_from_literature", "prior_pilot"] },
    "evidence_refs": { "type": "array", "items": { "type": "string" } },
    "rationale": { "type": "string", "minLength": 1 },
    "calibration_plan": { "type": "string", "minLength": 1 },
    "calibration_study": { "type": ["string", "null"] }
  }
}
```

`data/schema/assessment_rule.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Assessment rule",
  "type": "object",
  "additionalProperties": false,
  "required": ["id", "skill", "inputs", "state_criteria"],
  "$defs": {
    "criterion": {
      "type": "object",
      "additionalProperties": false,
      "required": ["description", "parameters", "requires_dimensions"],
      "properties": {
        "description": { "type": "string", "minLength": 1 },
        "parameters": { "type": "array", "items": { "type": "string" } },
        "requires_dimensions": {
          "type": "array",
          "minItems": 1,
          "uniqueItems": true,
          "items": { "enum": ["performance", "independence", "transfer"] }
        }
      }
    }
  },
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z0-9_]+(\\.[a-z0-9_-]+)+$" },
    "skill": { "type": "string" },
    "inputs": { "type": "array", "minItems": 1, "uniqueItems": true, "items": { "type": "string" } },
    "state_criteria": {
      "type": "object",
      "additionalProperties": false,
      "required": ["emerging", "developing", "secure", "transfer"],
      "properties": {
        "emerging": { "$ref": "#/$defs/criterion" },
        "developing": { "$ref": "#/$defs/criterion" },
        "secure": { "$ref": "#/$defs/criterion" },
        "transfer": { "$ref": "#/$defs/criterion" }
      }
    }
  }
}
```

`data/schema/langpack.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Language pack",
  "type": "object",
  "additionalProperties": false,
  "required": ["id", "name", "status", "script", "slots_filled", "instruction_voice"],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z]{2,3}$" },
    "name": { "type": "string", "minLength": 1 },
    "status": { "enum": ["complete", "in_progress", "contract_only"] },
    "script": {
      "type": "object",
      "additionalProperties": false,
      "required": ["direction", "joining", "diacritics", "tonal", "notes"],
      "properties": {
        "direction": { "enum": ["ltr", "rtl"] },
        "joining": { "type": "boolean" },
        "diacritics": { "type": "boolean" },
        "tonal": { "type": "boolean" },
        "notes": { "type": "string", "minLength": 1 }
      }
    },
    "slots_filled": {
      "type": "array",
      "uniqueItems": true,
      "items": {
        "enum": [
          "listening", "vocabulary", "phonological_awareness", "print_concepts",
          "letter_knowledge", "sound_mapping", "word_building", "early_reading"
        ]
      }
    },
    "instruction_voice": { "type": "string", "minLength": 1 }
  }
}
```

`data/schema/mechanic.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Game mechanic",
  "type": "object",
  "additionalProperties": false,
  "required": ["id", "description"],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z0-9_-]+$" },
    "description": { "type": "string", "minLength": 1 }
  }
}
```

`data/schema/signal.schema.json`:

```json
{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "title": "Logged signal",
  "type": "object",
  "additionalProperties": false,
  "required": ["id", "kind", "description"],
  "properties": {
    "id": { "type": "string", "pattern": "^[a-z0-9_-]+$" },
    "kind": { "enum": ["learning", "engagement"] },
    "description": { "type": "string", "minLength": 1 }
  }
}
```

- [ ] **Step 4: Implement the schema rules**

`tools/validate/nova_validate/schema_rules.py`:

```python
"""Structural checks: JSON Schema validation and unique ids."""
from __future__ import annotations

import json
from collections import Counter
from pathlib import Path

from jsonschema import Draft202012Validator

from .model import Issue, Spec, error

# Spec attribute -> schema file in data/schema.
SCHEMA_FILES = {
    "skills": "skill.schema.json",
    "games": "game.schema.json",
    "transfer_tasks": "transfer_task.schema.json",
    "evidence": "evidence.schema.json",
    "parameters": "parameter.schema.json",
    "assessment_rules": "assessment_rule.schema.json",
    "langpacks": "langpack.schema.json",
    "mechanics": "mechanic.schema.json",
    "signals": "signal.schema.json",
}


def load_schema(schema_dir: Path, filename: str) -> dict:
    return json.loads((Path(schema_dir) / filename).read_text(encoding="utf-8"))


def check_schemas(spec: Spec, schema_dir: Path) -> list[Issue]:
    issues: list[Issue] = []
    for attr, filename in SCHEMA_FILES.items():
        schema = load_schema(schema_dir, filename)
        Draft202012Validator.check_schema(schema)
        validator = Draft202012Validator(schema)
        for record in getattr(spec, attr):
            for problem in sorted(
                validator.iter_errors(record),
                key=lambda e: [str(part) for part in e.absolute_path],
            ):
                path = "/".join(str(part) for part in problem.absolute_path) or "<root>"
                where = f"{attr}:{record.get('id', '<no id>')}"
                issues.append(error("schema", where, f"{path}: {problem.message}"))
    return issues


def check_unique_ids(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    for attr in SCHEMA_FILES:
        counts = Counter(record.get("id") for record in getattr(spec, attr))
        for record_id, count in counts.items():
            if count > 1:
                issues.append(error("unique-id", f"{attr}:{record_id}", f"id is used {count} times"))
    return issues
```

- [ ] **Step 5: Run the tests to verify they pass**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `18 passed`.

- [ ] **Step 6: Commit**

```bash
cd /d/hamada/nova
git add data/schema tools/validate
git commit -m "Add JSON Schemas and structural validation" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 3: Evidence rules

**Files:**
- Create: `tools/validate/nova_validate/evidence_rules.py`
- Test: `tools/validate/tests/test_evidence_rules.py`

**Interfaces:**
- Consumes: `EVIDENCE_TYPES`, `STRENGTH_CAPS`, `STRENGTH_RANK`, `index_by_id` from `model`.
- Produces: `computed_basis(evidence_refs, evidence_index) -> str`; `check_evidence_entries(spec)` (rules `evidence-cap`, `evidence-verified`); `check_evidence_basis(spec)` (rules `evidence-ref`, `evidence-basis`).

- [ ] **Step 1: Write the failing test**

`tools/validate/tests/test_evidence_rules.py`:

```python
from nova_validate.evidence_rules import check_evidence_basis, check_evidence_entries, computed_basis
from nova_validate.model import index_by_id
from tests.factory import get, make_spec, rules_of


def test_valid_factory_spec_has_no_evidence_issues():
    spec = make_spec()
    assert check_evidence_entries(spec) == []
    assert check_evidence_basis(spec) == []


def test_design_inference_is_capped_at_emerging():
    spec = make_spec()
    get(spec.evidence, "ev.test.design")["evidence_strength"] = "moderate"
    assert rules_of(check_evidence_entries(spec)) == {"evidence-cap"}


def test_expert_consensus_is_capped_at_moderate():
    spec = make_spec()
    entry = get(spec.evidence, "ev.test.design")
    entry["evidence_type"] = "expert_consensus"
    entry["evidence_strength"] = "moderate"
    assert check_evidence_entries(spec) == []
    entry["evidence_strength"] = "strong"
    assert rules_of(check_evidence_entries(spec)) == {"evidence-cap"}


def test_empirical_evidence_must_be_verified():
    spec = make_spec()
    get(spec.evidence, "ev.test.meta")["verified"] = False
    assert rules_of(check_evidence_entries(spec)) == {"evidence-verified"}


def test_framework_evidence_must_be_verified():
    spec = make_spec()
    get(spec.evidence, "ev.test.framework")["verified"] = False
    assert rules_of(check_evidence_entries(spec)) == {"evidence-verified"}


def test_judgment_evidence_does_not_need_verification():
    spec = make_spec()
    assert get(spec.evidence, "ev.test.design")["verified"] is False
    assert check_evidence_entries(spec) == []


def test_computed_basis_precedence():
    index = index_by_id(make_spec().evidence)
    assert computed_basis(["ev.test.design"], index) == "judgment"
    assert computed_basis(["ev.test.framework"], index) == "framework"
    assert computed_basis(["ev.test.meta"], index) == "empirical"
    assert computed_basis(["ev.test.design", "ev.test.framework"], index) == "framework"
    assert computed_basis(["ev.test.framework", "ev.test.meta"], index) == "empirical"
    assert computed_basis(["ev.test.design", "ev.test.meta", "ev.test.framework"], index) == "empirical"


def test_skill_declaring_empirical_from_judgment_evidence_is_rejected():
    spec = make_spec()
    spec.skills[0]["evidence_basis"] = "empirical"
    issues = check_evidence_basis(spec)
    assert rules_of(issues) == {"evidence-basis"}
    assert "skill:math.count.one-to-one-5" in issues[0].where


def test_any_empirical_reference_forces_empirical_basis():
    spec = make_spec()
    skill = spec.skills[0]
    skill["evidence_refs"] = ["ev.test.design", "ev.test.meta"]
    skill["evidence_basis"] = "judgment"
    assert rules_of(check_evidence_basis(spec)) == {"evidence-basis"}
    skill["evidence_basis"] = "empirical"
    assert check_evidence_basis(spec) == []


def test_framework_plus_empirical_cannot_declare_framework():
    spec = make_spec()
    skill = spec.skills[0]
    skill["evidence_refs"] = ["ev.test.framework", "ev.test.meta"]
    skill["evidence_basis"] = "framework"
    assert rules_of(check_evidence_basis(spec)) == {"evidence-basis"}


def test_judgment_plus_framework_must_declare_framework():
    spec = make_spec()
    skill = spec.skills[0]
    skill["evidence_refs"] = ["ev.test.design", "ev.test.framework"]
    skill["evidence_basis"] = "judgment"
    assert rules_of(check_evidence_basis(spec)) == {"evidence-basis"}
    skill["evidence_basis"] = "framework"
    assert check_evidence_basis(spec) == []


def test_unknown_evidence_reference_is_reported_once():
    spec = make_spec()
    spec.skills[0]["evidence_refs"] = ["ev.test.missing"]
    issues = check_evidence_basis(spec)
    assert rules_of(issues) == {"evidence-ref"}
    assert len(issues) == 1


def test_game_basis_is_checked_too():
    spec = make_spec()
    spec.games[0]["evidence_basis"] = "empirical"
    issues = check_evidence_basis(spec)
    assert rules_of(issues) == {"evidence-basis"}
    assert issues[0].where == "game:game.math.bear-snacks"


def test_prerequisite_edge_evidence_must_resolve():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [
        {"skill": "math.count.one-to-one-5", "evidence_refs": ["ev.test.missing"]}
    ]
    assert rules_of(check_evidence_basis(spec)) == {"evidence-ref"}


def test_prerequisite_edge_with_valid_evidence_passes():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [
        {"skill": "math.count.one-to-one-5", "evidence_refs": ["ev.test.meta"]}
    ]
    assert check_evidence_basis(spec) == []
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/Scripts/python.exe -m pytest tests/test_evidence_rules.py -q`
Expected: collection error, `ModuleNotFoundError: No module named 'nova_validate.evidence_rules'`.

- [ ] **Step 3: Implement**

`tools/validate/nova_validate/evidence_rules.py`:

```python
"""Evidence rules: type/strength caps, verification, and deterministic basis."""
from __future__ import annotations

from .model import (
    EVIDENCE_TYPES,
    STRENGTH_CAPS,
    STRENGTH_RANK,
    Issue,
    Record,
    Spec,
    error,
    index_by_id,
)


def computed_basis(evidence_refs: list[str], evidence_index: dict[str, Record]) -> str:
    """Precedence empirical > framework > judgment, over the cited evidence that exists."""
    classes = {
        EVIDENCE_TYPES[evidence_index[ref]["evidence_type"]]
        for ref in evidence_refs
        if ref in evidence_index
    }
    for evidence_class in ("empirical", "framework"):
        if evidence_class in classes:
            return evidence_class
    return "judgment"


def check_evidence_entries(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    for entry in spec.evidence:
        where = f"evidence:{entry['id']}"
        kind = entry["evidence_type"]
        cap = STRENGTH_CAPS.get(kind)
        if cap and STRENGTH_RANK[entry["evidence_strength"]] > STRENGTH_RANK[cap]:
            issues.append(error(
                "evidence-cap", where,
                f"{kind} evidence is capped at '{cap}' but is rated '{entry['evidence_strength']}'",
            ))
        if EVIDENCE_TYPES[kind] != "judgment" and not entry["verified"]:
            issues.append(error(
                "evidence-verified", where,
                "empirical and framework evidence must be verified against the primary source (verified: true)",
            ))
    return issues


def check_evidence_basis(spec: Spec) -> list[Issue]:
    index = index_by_id(spec.evidence)
    issues: list[Issue] = []

    for label, records in (("skill", spec.skills), ("game", spec.games)):
        for record in records:
            where = f"{label}:{record['id']}"
            refs = record["evidence_refs"]
            unknown = [ref for ref in refs if ref not in index]
            for ref in unknown:
                issues.append(error("evidence-ref", where, f"cites unknown evidence '{ref}'"))
            if len(unknown) == len(refs):
                continue  # nothing resolvable to compute a basis from
            expected = computed_basis(refs, index)
            if record["evidence_basis"] != expected:
                issues.append(error(
                    "evidence-basis", where,
                    f"declares '{record['evidence_basis']}' but the cited evidence gives '{expected}' "
                    "(precedence: empirical > framework > judgment)",
                ))

    for skill in spec.skills:
        for edge in skill["prerequisites"]:
            for ref in edge.get("evidence_refs", []):
                if ref not in index:
                    issues.append(error(
                        "evidence-ref", f"skill:{skill['id']}",
                        f"prerequisite edge to '{edge['skill']}' cites unknown evidence '{ref}'",
                    ))
    return issues
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `33 passed`.

- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add tools/validate
git commit -m "Add evidence rules: caps, verification, deterministic basis" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 4: Skill graph rules

**Files:**
- Create: `tools/validate/nova_validate/graph_rules.py`
- Test: `tools/validate/tests/test_graph_rules.py`

**Interfaces:**
- Consumes: `DEEP_AGE_WINDOW`, `DEEP_DOMAINS`, `DEEP_LANGUAGES` from `model`.
- Produces: `find_cycle(edges: dict[str, list[str]]) -> list[str] | None`; `is_deep_candidate(skill) -> bool`; `check_skill_graph(spec)` (rules `age-range`, `prerequisite`, `deep-scope`, `cycle`).

- [ ] **Step 1: Write the failing test**

`tools/validate/tests/test_graph_rules.py`:

```python
from nova_validate.graph_rules import check_skill_graph, find_cycle, is_deep_candidate
from tests.factory import get, make_spec, rules_of


def skill(ages, domains, scope="universal", language=None):
    record = {"age_range": ages, "domains": domains, "scope": scope}
    if language:
        record["language"] = language
    return record


def test_valid_factory_spec_has_a_clean_graph():
    assert check_skill_graph(make_spec()) == []


def test_missing_prerequisite_is_reported():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [{"skill": "math.count.nope"}]
    issues = check_skill_graph(spec)
    assert rules_of(issues) == {"prerequisite"}
    assert "math.count.nope" in issues[0].message


def test_self_prerequisite_is_reported():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [{"skill": "math.count.cardinality"}]
    assert rules_of(check_skill_graph(spec)) == {"prerequisite"}


def test_cycle_is_reported_with_its_path():
    spec = make_spec()
    get(spec.skills, "math.count.one-to-one-5")["prerequisites"] = [{"skill": "math.count.cardinality"}]
    issues = check_skill_graph(spec)
    assert rules_of(issues) == {"cycle"}
    assert "math.count.one-to-one-5" in issues[0].message and "math.count.cardinality" in issues[0].message


def test_find_cycle_unit():
    assert find_cycle({"a": ["b"], "b": ["c"], "c": []}) is None
    assert find_cycle({"a": ["b"], "b": ["a"]}) == ["a", "b", "a"]
    assert find_cycle({"a": ["b"], "b": ["c"], "c": ["b"]}) == ["b", "c", "b"]
    assert find_cycle({"a": ["b", "c"], "b": ["d"], "c": ["d"], "d": []}) is None


def test_reversed_age_range_is_reported():
    spec = make_spec()
    spec.skills[0]["age_range"] = [5, 3]
    assert rules_of(check_skill_graph(spec)) == {"age-range"}


def test_deep_candidate_must_be_marked_deep():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["deep_scope"] = False
    issues = check_skill_graph(spec)
    assert rules_of(issues) == {"deep-scope"}
    assert issues[0].where == "skill:math.count.cardinality"


def test_non_candidate_may_still_be_deep():
    spec = make_spec()
    get(spec.skills, "soc.emotion.name-basic")["deep_scope"] = True
    assert check_skill_graph(spec) == []


def test_deep_candidate_age_window_is_exclusive():
    assert is_deep_candidate(skill([3, 4], ["math"]))
    assert is_deep_candidate(skill([5, 6], ["math"]))
    assert is_deep_candidate(skill([2, 4], ["memory"]))
    assert not is_deep_candidate(skill([2, 3], ["math"]))
    assert not is_deep_candidate(skill([6, 8], ["math"]))


def test_deep_candidate_domains():
    assert is_deep_candidate(skill([4, 5], ["executive_function"]))
    assert not is_deep_candidate(skill([4, 5], ["attention"]))
    assert not is_deep_candidate(skill([4, 5], ["social_emotional"]))


def test_literacy_is_deep_only_for_arabic_and_english_specific_skills():
    assert is_deep_candidate(skill([4, 5], ["language_literacy"], "language-specific", "ar"))
    assert is_deep_candidate(skill([4, 5], ["language_literacy"], "language-specific", "en"))
    assert not is_deep_candidate(skill([4, 5], ["language_literacy"], "language-specific", "zh"))
    assert not is_deep_candidate(skill([4, 5], ["language_literacy"]))
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/Scripts/python.exe -m pytest tests/test_graph_rules.py -q`
Expected: collection error, `ModuleNotFoundError: No module named 'nova_validate.graph_rules'`.

- [ ] **Step 3: Implement**

`tools/validate/nova_validate/graph_rules.py`:

```python
"""Skill graph rules: references, cycles, age ranges, and deep-scope classification."""
from __future__ import annotations

from .model import (
    DEEP_AGE_WINDOW,
    DEEP_DOMAINS,
    DEEP_LANGUAGES,
    Issue,
    Record,
    Spec,
    error,
)


def find_cycle(edges: dict[str, list[str]]) -> list[str] | None:
    """Return one cycle as [a, b, ..., a], or None. Edges point from a skill to its prerequisites."""
    white, grey, black = 0, 1, 2
    color = {node: white for node in edges}
    for start in edges:
        if color[start] != white:
            continue
        color[start] = grey
        path = [start]
        stack = [(start, iter(edges[start]))]
        while stack:
            node, neighbours = stack[-1]
            for nxt in neighbours:
                if nxt not in color:
                    continue
                if color[nxt] == grey:
                    return path[path.index(nxt):] + [nxt]
                if color[nxt] == white:
                    color[nxt] = grey
                    path.append(nxt)
                    stack.append((nxt, iter(edges[nxt])))
                    break
            else:
                color[node] = black
                path.pop()
                stack.pop()
    return None


def is_deep_candidate(skill: Record) -> bool:
    """True if the skill belongs in the deep-coverage set (spec 3.1).

    The age window is exclusive at both ends: a skill qualifies when its range
    starts before age 6 and ends after age 3.
    """
    low, high = skill["age_range"]
    window_start, window_end = DEEP_AGE_WINDOW
    if not (low < window_end and high > window_start):
        return False
    if DEEP_DOMAINS & set(skill["domains"]):
        return True
    return (
        "language_literacy" in skill["domains"]
        and skill["scope"] == "language-specific"
        and skill.get("language") in DEEP_LANGUAGES
    )


def check_skill_graph(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    ids = {skill["id"] for skill in spec.skills}
    edges: dict[str, list[str]] = {}

    for skill in spec.skills:
        where = f"skill:{skill['id']}"
        low, high = skill["age_range"]
        if low > high:
            issues.append(error("age-range", where, f"age_range {[low, high]} starts after it ends"))

        targets: list[str] = []
        for edge in skill["prerequisites"]:
            target = edge["skill"]
            if target == skill["id"]:
                issues.append(error("prerequisite", where, "lists itself as a prerequisite"))
            elif target not in ids:
                issues.append(error("prerequisite", where, f"prerequisite '{target}' does not exist"))
            else:
                targets.append(target)
        edges[skill["id"]] = targets

        if is_deep_candidate(skill) and not skill["deep_scope"]:
            issues.append(error(
                "deep-scope", where,
                "falls in the deep-coverage set (EF, memory, math, Arabic/English literacy, ages 3-6) "
                "and must set deep_scope: true",
            ))

    cycle = find_cycle(edges)
    if cycle:
        issues.append(error("cycle", "skills", "prerequisite cycle: " + " -> ".join(cycle)))
    return issues
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `44 passed`.

- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add tools/validate
git commit -m "Add skill graph rules: references, cycles, deep-scope classification" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 5: Parameter and assessment rules

**Files:**
- Create: `tools/validate/nova_validate/parameter_rules.py`, `assessment_rules.py`
- Test: `tools/validate/tests/test_parameter_rules.py`, `test_assessment_rules.py`

**Interfaces:**
- Produces: `check_parameters(spec)` (rules `parameter-status`, `parameter-basis`); `check_assessment_rules(spec)` (rules `assessment-skill`, `assessment-signal`, `engagement-signal`, `assessment-parameter`, `assessment-dimension`); `assessment_rules.REQUIRED_DIMENSION: dict[str, str]`.

- [ ] **Step 1: Write the failing tests**

`tools/validate/tests/test_parameter_rules.py`:

```python
from nova_validate.parameter_rules import check_parameters
from tests.factory import get, make_spec, rules_of


def test_valid_factory_parameters_pass():
    assert check_parameters(make_spec()) == []


def test_validated_without_a_study_is_rejected():
    spec = make_spec()
    get(spec.parameters, "param.test.advance")["status"] = "validated"
    assert rules_of(check_parameters(spec)) == {"parameter-status"}


def test_pilot_calibrated_without_a_study_is_rejected():
    spec = make_spec()
    get(spec.parameters, "param.test.advance")["status"] = "pilot_calibrated"
    assert rules_of(check_parameters(spec)) == {"parameter-status"}


def test_calibrated_with_a_study_is_accepted():
    spec = make_spec()
    parameter = get(spec.parameters, "param.test.advance")
    parameter["status"] = "pilot_calibrated"
    parameter["calibration_study"] = "study-2027-pilot-1"
    assert check_parameters(spec) == []


def test_borrowed_basis_requires_evidence():
    spec = make_spec()
    get(spec.parameters, "param.test.advance")["basis"] = "borrowed_from_literature"
    assert rules_of(check_parameters(spec)) == {"parameter-basis"}


def test_borrowed_basis_with_known_evidence_passes():
    spec = make_spec()
    parameter = get(spec.parameters, "param.test.advance")
    parameter["basis"] = "borrowed_from_literature"
    parameter["evidence_refs"] = ["ev.test.meta"]
    assert check_parameters(spec) == []


def test_unknown_evidence_ref_is_rejected():
    spec = make_spec()
    get(spec.parameters, "param.test.advance")["evidence_refs"] = ["ev.test.missing"]
    assert rules_of(check_parameters(spec)) == {"parameter-basis"}
```

`tools/validate/tests/test_assessment_rules.py`:

```python
from nova_validate.assessment_rules import check_assessment_rules
from tests.factory import get, make_spec, rules_of

RULE = "rule.math.count.cardinality"


def test_valid_factory_rules_pass():
    assert check_assessment_rules(make_spec()) == []


def test_rule_for_unknown_skill_is_rejected():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["skill"] = "math.count.nope"
    assert rules_of(check_assessment_rules(spec)) == {"assessment-skill"}


def test_engagement_signal_cannot_feed_mastery():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["inputs"] = ["accuracy", "session_time"]
    issues = check_assessment_rules(spec)
    assert rules_of(issues) == {"engagement-signal"}
    assert "session_time" in issues[0].message


def test_completion_is_an_engagement_signal_too():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["inputs"] = ["completion"]
    assert rules_of(check_assessment_rules(spec)) == {"engagement-signal"}


def test_unknown_signal_is_rejected():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["inputs"] = ["mystery"]
    assert rules_of(check_assessment_rules(spec)) == {"assessment-signal"}


def test_unknown_parameter_is_rejected():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["state_criteria"]["secure"]["parameters"] = ["param.test.nope"]
    assert rules_of(check_assessment_rules(spec)) == {"assessment-parameter"}


def test_secure_cannot_rest_on_performance_alone():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["state_criteria"]["secure"]["requires_dimensions"] = ["performance"]
    issues = check_assessment_rules(spec)
    assert rules_of(issues) == {"assessment-dimension"}
    assert "secure" in issues[0].message


def test_transfer_requires_the_transfer_dimension():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["state_criteria"]["transfer"]["requires_dimensions"] = ["performance", "independence"]
    issues = check_assessment_rules(spec)
    assert rules_of(issues) == {"assessment-dimension"}
    assert "transfer" in issues[0].message


def test_emerging_and_developing_require_performance():
    spec = make_spec()
    criteria = get(spec.assessment_rules, RULE)["state_criteria"]
    criteria["emerging"]["requires_dimensions"] = ["independence"]
    criteria["developing"]["requires_dimensions"] = ["independence"]
    assert len(check_assessment_rules(spec)) == 2
```

- [ ] **Step 2: Run the tests to verify they fail**

Run: `.venv/Scripts/python.exe -m pytest tests/test_parameter_rules.py tests/test_assessment_rules.py -q`
Expected: collection errors, `ModuleNotFoundError` for `nova_validate.parameter_rules` and `nova_validate.assessment_rules`.

- [ ] **Step 3: Implement**

`tools/validate/nova_validate/parameter_rules.py`:

```python
"""Parameter rules: nothing is 'validated' without a calibration study (spec 3.5)."""
from __future__ import annotations

from .model import Issue, Spec, error


def check_parameters(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    evidence_ids = {entry["id"] for entry in spec.evidence}

    for parameter in spec.parameters:
        where = f"parameter:{parameter['id']}"
        status = parameter["status"]
        if status in ("pilot_calibrated", "validated") and not parameter.get("calibration_study"):
            issues.append(error(
                "parameter-status", where,
                f"status '{status}' requires a calibration_study; otherwise it must stay 'provisional'",
            ))

        refs = parameter.get("evidence_refs", [])
        if parameter["basis"] == "borrowed_from_literature" and not refs:
            issues.append(error(
                "parameter-basis", where,
                "basis 'borrowed_from_literature' requires at least one evidence ref",
            ))
        for ref in refs:
            if ref not in evidence_ids:
                issues.append(error("parameter-basis", where, f"cites unknown evidence '{ref}'"))
    return issues
```

`tools/validate/nova_validate/assessment_rules.py`:

```python
"""Assessment rule checks: learning signals only, and dimensions each state must require."""
from __future__ import annotations

from .model import Issue, Spec, error

# Each mastery state must draw on this dimension (spec 3.2 and 3.4). Secure cannot be
# reached on in-game performance alone, and Transfer needs a passed transfer probe.
REQUIRED_DIMENSION = {
    "emerging": "performance",
    "developing": "performance",
    "secure": "independence",
    "transfer": "transfer",
}


def check_assessment_rules(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    skill_ids = {skill["id"] for skill in spec.skills}
    parameter_ids = {parameter["id"] for parameter in spec.parameters}
    signal_kind = {signal["id"]: signal["kind"] for signal in spec.signals}

    for rule in spec.assessment_rules:
        where = f"assessment_rule:{rule['id']}"
        if rule["skill"] not in skill_ids:
            issues.append(error("assessment-skill", where, f"skill '{rule['skill']}' does not exist"))

        for signal in rule["inputs"]:
            kind = signal_kind.get(signal)
            if kind is None:
                issues.append(error("assessment-signal", where, f"input signal '{signal}' is not in signals.yaml"))
            elif kind != "learning":
                issues.append(error(
                    "engagement-signal", where,
                    f"consumes {kind} signal '{signal}'; only learning signals may feed mastery",
                ))

        for state, criterion in rule["state_criteria"].items():
            for parameter in criterion["parameters"]:
                if parameter not in parameter_ids:
                    issues.append(error(
                        "assessment-parameter", where,
                        f"state '{state}' references unknown parameter '{parameter}'",
                    ))
            needed = REQUIRED_DIMENSION[state]
            if needed not in criterion["requires_dimensions"]:
                issues.append(error(
                    "assessment-dimension", where,
                    f"state '{state}' must require the {needed} dimension",
                ))
    return issues
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `60 passed`.

- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add tools/validate
git commit -m "Add parameter and assessment rules" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 6: Game and transfer-task rules (difficulty model)

**Files:**
- Create: `tools/validate/nova_validate/game_rules.py`
- Test: `tools/validate/tests/test_game_rules.py`

**Interfaces:**
- Consumes: `DIFFICULTY_DIMENSIONS`, `error`, `warning` from `model`.
- Produces: `check_games(spec)` (errors: `age-range`, `mechanic`, `game-skill`, `game-signal`, `game-parameter`, `game-language`, `difficulty`, `difficulty-anchor`, `probe`; warning: `difficulty-step`).

- [ ] **Step 1: Write the failing test**

`tools/validate/tests/test_game_rules.py`:

```python
from nova_validate.game_rules import check_games
from tests.factory import errors_of, get, make_spec, rules_of

GAME = "game.math.bear-snacks"


def test_valid_factory_games_pass():
    assert check_games(make_spec()) == []


def test_unknown_mechanic_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["mechanic_id"] = "teleport"
    assert rules_of(check_games(spec)) == {"mechanic"}


def test_unknown_skill_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["secondary_skills"] = ["math.count.nope"]
    assert rules_of(check_games(spec)) == {"game-skill"}


def test_unknown_signal_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["signals"] = ["accuracy", "mystery"]
    assert rules_of(check_games(spec)) == {"game-signal"}


def test_game_needs_at_least_one_learning_signal():
    spec = make_spec()
    get(spec.games, GAME)["signals"] = ["completion", "session_time"]
    issues = check_games(spec)
    assert rules_of(issues) == {"game-signal"}
    assert "learning" in issues[0].message


def test_unknown_progression_parameter_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["progression"]["advance_parameter"] = "param.test.nope"
    assert rules_of(check_games(spec)) == {"game-parameter"}


def test_language_dependency_needs_a_language_pack():
    spec = make_spec()
    get(spec.games, GAME)["language_dependencies"] = ["fr"]
    assert rules_of(check_games(spec)) == {"game-language"}


def test_varied_dimension_that_never_changes_is_rejected():
    spec = make_spec()
    for rung in get(spec.games, GAME)["difficulty"]["rungs"]:
        rung["values"]["item_complexity"] = 0
    issues = check_games(spec)
    assert rules_of(errors_of(issues)) == {"difficulty"}
    assert "item_complexity" in issues[0].message


def test_fixed_dimension_that_changes_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["difficulty"]["rungs"][1]["values"]["working_memory_load"] = 2
    issues = errors_of(check_games(spec))
    assert rules_of(issues) == {"difficulty"}
    assert "working_memory_load" in issues[0].message


def test_step_changing_two_dimensions_is_only_a_warning():
    spec = make_spec()
    rungs = get(spec.games, GAME)["difficulty"]["rungs"]
    rungs[1]["values"]["distractors"] = 1  # r2 now changes item_complexity and distractors
    issues = check_games(spec)
    assert errors_of(issues) == []
    assert rules_of(issues) == {"difficulty-step"}
    assert issues[0].level == "warning"


def test_duplicate_rung_ids_are_rejected():
    spec = make_spec()
    get(spec.games, GAME)["difficulty"]["rungs"][1]["id"] = "r1"
    assert "difficulty" in rules_of(check_games(spec))


def test_probe_must_target_a_skill_the_game_teaches():
    spec = make_spec()
    get(spec.games, GAME)["transfer_probes"][0]["skill"] = "soc.emotion.name-basic"
    assert rules_of(check_games(spec)) == {"probe"}


def test_probe_with_unknown_mechanic_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["transfer_probes"][0]["mechanic_id"] = "teleport"
    assert rules_of(check_games(spec)) == {"probe"}


def test_duplicate_probe_ids_are_rejected():
    spec = make_spec()
    probes = get(spec.games, GAME)["transfer_probes"]
    probes[1]["id"] = probes[0]["id"]
    assert rules_of(check_games(spec)) == {"probe"}


def test_transfer_task_with_unknown_mechanic_is_rejected():
    spec = make_spec()
    spec.transfer_tasks[0]["mechanic_id"] = "teleport"
    assert rules_of(check_games(spec)) == {"mechanic"}


def test_transfer_task_needs_a_learning_signal():
    spec = make_spec()
    spec.transfer_tasks[0]["signals"] = ["completion"]
    assert rules_of(check_games(spec)) == {"game-signal"}


def test_varied_dimension_without_anchors_is_rejected():
    spec = make_spec()
    del get(spec.games, GAME)["difficulty"]["anchors"]["distractors"]
    issues = check_games(spec)
    assert rules_of(issues) == {"difficulty-anchor"}
    assert "distractors" in issues[0].message


def test_value_beyond_the_named_anchors_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["difficulty"]["rungs"][2]["values"]["item_complexity"] = 2
    issues = errors_of(check_games(spec))
    assert rules_of(issues) == {"difficulty-anchor"}
    assert "value 2" in issues[0].message


def test_anchors_for_fixed_dimensions_are_optional():
    spec = make_spec()
    get(spec.games, GAME)["difficulty"]["anchors"]["independence"] = ["fully modelled"]
    assert check_games(spec) == []
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/Scripts/python.exe -m pytest tests/test_game_rules.py -q`
Expected: collection error, `ModuleNotFoundError: No module named 'nova_validate.game_rules'`.

- [ ] **Step 3: Implement**

`tools/validate/nova_validate/game_rules.py`:

```python
"""Game and transfer-task rules: references, vocabularies, and the difficulty model."""
from __future__ import annotations

from .model import DIFFICULTY_DIMENSIONS, Issue, Spec, error, warning


def check_games(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    skill_ids = {skill["id"] for skill in spec.skills}
    mechanic_ids = {mechanic["id"] for mechanic in spec.mechanics}
    signal_kind = {signal["id"]: signal["kind"] for signal in spec.signals}
    parameter_ids = {parameter["id"] for parameter in spec.parameters}
    language_ids = {pack["id"] for pack in spec.langpacks}

    for game in spec.games:
        where = f"game:{game['id']}"
        low, high = game["age_range"]
        if low > high:
            issues.append(error("age-range", where, f"age_range {[low, high]} starts after it ends"))

        if game["mechanic_id"] not in mechanic_ids:
            issues.append(error("mechanic", where, f"mechanic_id '{game['mechanic_id']}' is not in mechanics.yaml"))

        own_skills = set(game["primary_skills"]) | set(game["secondary_skills"])
        for skill in sorted(own_skills - skill_ids):
            issues.append(error("game-skill", where, f"skill '{skill}' does not exist"))

        for signal in game["signals"]:
            if signal not in signal_kind:
                issues.append(error("game-signal", where, f"signal '{signal}' is not in signals.yaml"))
        if not any(signal_kind.get(signal) == "learning" for signal in game["signals"]):
            issues.append(error("game-signal", where, "logs no learning signal, so it cannot be assessed"))

        for role in ("advance_parameter", "retreat_parameter"):
            parameter = game["progression"][role]
            if parameter not in parameter_ids:
                issues.append(error("game-parameter", where, f"{role} '{parameter}' does not exist"))

        for language in game["language_dependencies"]:
            if language not in language_ids:
                issues.append(error("game-language", where, f"language dependency '{language}' has no language pack"))

        issues.extend(_check_difficulty(game, where))

        probe_ids: set[str] = set()
        for probe in game["transfer_probes"]:
            if probe["id"] in probe_ids:
                issues.append(error("probe", where, f"probe id '{probe['id']}' is used twice"))
            probe_ids.add(probe["id"])
            if probe["skill"] not in own_skills:
                issues.append(error("probe", where, f"probe '{probe['id']}' targets skill '{probe['skill']}' which the game does not teach"))
            if probe["mechanic_id"] not in mechanic_ids:
                issues.append(error("probe", where, f"probe '{probe['id']}' names unknown mechanic '{probe['mechanic_id']}'"))

    for task in spec.transfer_tasks:
        where = f"transfer_task:{task['id']}"
        if task["mechanic_id"] not in mechanic_ids:
            issues.append(error("mechanic", where, f"mechanic_id '{task['mechanic_id']}' is not in mechanics.yaml"))
        for skill in task["skills"]:
            if skill not in skill_ids:
                issues.append(error("game-skill", where, f"skill '{skill}' does not exist"))
        for signal in task["signals"]:
            if signal not in signal_kind:
                issues.append(error("game-signal", where, f"signal '{signal}' is not in signals.yaml"))
        if not any(signal_kind.get(signal) == "learning" for signal in task["signals"]):
            issues.append(error("game-signal", where, "logs no learning signal, so it cannot be assessed"))
    return issues


def _check_difficulty(game, where: str) -> list[Issue]:
    issues: list[Issue] = []
    difficulty = game["difficulty"]
    rungs = difficulty["rungs"]
    varied = set(difficulty["varied"])

    rung_ids = [rung["id"] for rung in rungs]
    if len(set(rung_ids)) != len(rung_ids):
        issues.append(error("difficulty", where, "rung ids are not unique"))

    anchors = difficulty["anchors"]
    for dimension in DIFFICULTY_DIMENSIONS:
        values = {rung["values"][dimension] for rung in rungs}
        if dimension in varied and len(values) < 2:
            issues.append(error("difficulty", where, f"'{dimension}' is declared varied but never changes"))
        if dimension in varied:
            labels = anchors.get(dimension, [])
            if max(values) >= len(labels):
                issues.append(error(
                    "difficulty-anchor", where,
                    f"'{dimension}' reaches value {max(values)} but has only {len(labels)} named anchor(s); "
                    "every value a varied dimension takes needs a label (anchors[dimension][value])",
                ))
        if dimension not in varied and len(values) > 1:
            issues.append(error("difficulty", where, f"'{dimension}' is held fixed but changes between rungs"))

    for previous, current in zip(rungs, rungs[1:]):
        changed = [d for d in DIFFICULTY_DIMENSIONS if previous["values"][d] != current["values"][d]]
        if len(changed) > 1:
            issues.append(warning(
                "difficulty-step", where,
                f"rung '{current['id']}' changes {len(changed)} dimensions at once ({', '.join(changed)}); "
                "errors become harder to diagnose",
            ))
    return issues
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `79 passed`.

- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add tools/validate
git commit -m "Add game rules: difficulty vectors, anchors, vocabularies" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 7: Transfer probe and deep-coverage rules

**Files:**
- Create: `tools/validate/nova_validate/coverage_rules.py`
- Test: `tools/validate/tests/test_coverage_rules.py`

**Interfaces:**
- Produces: `probe_problems(game, probe, targets) -> list[str]` (empty means valid); `check_probes(spec)` (rule `probe`); `check_deep_coverage(spec)` (rule `deep-coverage`).

- [ ] **Step 1: Write the failing test**

`tools/validate/tests/test_coverage_rules.py`:

```python
from nova_validate.coverage_rules import check_deep_coverage, check_probes
from tests.factory import get, make_spec, rules_of

GAME = "game.math.bear-snacks"
ONE_TO_ONE = "skill:math.count.one-to-one-5"
CARDINALITY = "skill:math.count.cardinality"


def where_of(issues):
    return {issue.where for issue in issues}


def probe(spec, probe_id):
    for candidate in get(spec.games, GAME)["transfer_probes"]:
        if candidate["id"] == probe_id:
            return candidate
    raise KeyError(probe_id)


def add_reskin_game(spec):
    reskin = dict(get(spec.games, "game.math.bear-snacks"))
    reskin["id"] = "game.math.penguin-fish"
    reskin["name_key"] = "game.math.penguin-fish.name"
    reskin["transfer_probes"] = []
    spec.games.append(reskin)
    return reskin


def test_valid_factory_spec_is_covered():
    spec = make_spec()
    assert check_probes(spec) == []
    assert check_deep_coverage(spec) == []


def test_deep_skill_without_a_game_is_reported():
    spec = make_spec()
    spec.games = [g for g in spec.games if g["id"] != "game.lit.ar.letter-catch"]
    issues = check_deep_coverage(spec)
    assert "skill:lit.ar.letter.recognize-isolated" in where_of(issues)
    assert any("no game" in issue.message for issue in issues)


def test_deep_skill_without_an_assessment_rule_is_reported():
    spec = make_spec()
    spec.assessment_rules = [r for r in spec.assessment_rules if r["skill"] != "math.count.cardinality"]
    issues = check_deep_coverage(spec)
    assert where_of(issues) == {CARDINALITY}
    assert "assessment rule" in issues[0].message


def test_single_mechanic_is_not_enough():
    spec = make_spec()
    spec.transfer_tasks = [t for t in spec.transfer_tasks if t["id"] != "task.math.count-objects-at-home"]
    issues = check_deep_coverage(spec)
    assert ONE_TO_ONE in where_of(issues)
    assert any("distinct mechanic" in issue.message for issue in issues)


def test_reskin_does_not_add_a_second_mechanic():
    spec = make_spec()
    add_reskin_game(spec)
    spec.transfer_tasks = [t for t in spec.transfer_tasks if t["id"] != "task.math.count-objects-at-home"]
    issues = check_deep_coverage(spec)
    assert any(i.where == ONE_TO_ONE and "distinct mechanic" in i.message for i in issues)


def test_cross_game_probe_pointing_at_a_reskin_is_invalid():
    spec = make_spec()
    reskin = add_reskin_game(spec)
    entry = probe(spec, "probe.one-to-one")
    entry["mechanic_id"] = reskin["mechanic_id"]
    entry["task_ref"] = reskin["id"]
    issues = check_probes(spec)
    assert rules_of(issues) == {"probe"}
    assert "reskin" in issues[0].message
    coverage = check_deep_coverage(spec)
    assert any(i.where == ONE_TO_ONE and "cross_game" in i.message for i in coverage)


def test_probe_mechanic_must_match_its_target():
    spec = make_spec()
    probe(spec, "probe.one-to-one")["mechanic_id"] = "print-hunt"
    issues = check_probes(spec)
    assert rules_of(issues) == {"probe"}
    assert "uses 'physical-counting'" in issues[0].message


def test_probe_task_ref_must_resolve():
    spec = make_spec()
    probe(spec, "probe.one-to-one")["task_ref"] = "task.nope"
    issues = check_probes(spec)
    assert rules_of(issues) == {"probe"}
    assert "task.nope" in issues[0].message


def test_probe_target_must_cover_the_probed_skill():
    spec = make_spec()
    entry = probe(spec, "probe.one-to-one")
    entry["mechanic_id"] = "print-hunt"
    entry["task_ref"] = "task.lit.ar.find-letter-in-print"
    issues = check_probes(spec)
    assert rules_of(issues) == {"probe"}
    assert "does not cover skill" in issues[0].message


def test_cross_context_probe_may_reuse_the_same_mechanic():
    spec = make_spec()
    entry = probe(spec, "probe.cardinality-later")
    entry["mechanic_id"] = "drag-to-count"
    entry["task_ref"] = GAME
    assert check_probes(spec) == []


def test_two_games_with_different_mechanics_satisfy_the_requirement():
    spec = make_spec()
    spec.transfer_tasks = [t for t in spec.transfer_tasks if t["id"] != "task.math.count-objects-at-home"]
    entry = probe(spec, "probe.cardinality")
    entry["mechanic_id"] = "match-symbol-to-quantity"
    entry["task_ref"] = "game.math.number-match"
    issues = check_deep_coverage(spec)
    assert CARDINALITY not in where_of(issues)


def test_deep_skill_needs_a_valid_cross_game_probe():
    spec = make_spec()
    get(spec.games, "game.lit.ar.letter-catch")["transfer_probes"] = []
    issues = check_deep_coverage(spec)
    assert where_of(issues) == {"skill:lit.ar.letter.recognize-isolated"}
    assert "cross_game" in issues[0].message


def test_cross_context_alone_does_not_satisfy_the_cross_game_requirement():
    spec = make_spec()
    get(spec.games, "game.lit.ar.letter-catch")["transfer_probes"][0]["type"] = "cross_context"
    issues = check_deep_coverage(spec)
    assert any("cross_game" in issue.message for issue in issues)


def test_non_deep_skills_need_no_coverage():
    spec = make_spec()
    assert not get(spec.skills, "soc.emotion.name-basic")["deep_scope"]
    assert "skill:soc.emotion.name-basic" not in where_of(check_deep_coverage(spec))
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/Scripts/python.exe -m pytest tests/test_coverage_rules.py -q`
Expected: collection error, `ModuleNotFoundError: No module named 'nova_validate.coverage_rules'`.

- [ ] **Step 3: Implement**

`tools/validate/nova_validate/coverage_rules.py`:

```python
"""Transfer-probe validity and deep-scope coverage (spec 3.4).

A deep-scope skill needs at least two distinct game mechanics: two games with
different mechanic_ids, or one game plus a separately specified transfer task on a
different mechanic. A cross_game probe never counts if it only reskins the same
mechanic.
"""
from __future__ import annotations

from collections import defaultdict

from .model import Issue, Record, Spec, error


def _targets(spec: Spec) -> dict[str, Record]:
    """Everything a probe's task_ref may point at: games and transfer tasks."""
    targets = {game["id"]: game for game in spec.games}
    targets.update({task["id"]: task for task in spec.transfer_tasks})
    return targets


def _target_skills(target: Record) -> set[str]:
    return (
        set(target.get("primary_skills", []))
        | set(target.get("secondary_skills", []))
        | set(target.get("skills", []))
    )


def probe_problems(game: Record, probe: Record, targets: dict[str, Record]) -> list[str]:
    """Why a probe is invalid; an empty list means it is valid."""
    target = targets.get(probe["task_ref"])
    if target is None:
        return [f"task_ref '{probe['task_ref']}' is not a game or transfer task"]

    problems: list[str] = []
    if target["mechanic_id"] != probe["mechanic_id"]:
        problems.append(
            f"names mechanic '{probe['mechanic_id']}' but '{probe['task_ref']}' uses '{target['mechanic_id']}'"
        )
    if probe["skill"] not in _target_skills(target):
        problems.append(f"'{probe['task_ref']}' does not cover skill '{probe['skill']}'")
    if probe["type"] == "cross_game" and probe["mechanic_id"] == game["mechanic_id"]:
        problems.append(
            f"cross_game probe reuses the declaring game's mechanic '{game['mechanic_id']}'; "
            "a reskin or new content on the same mechanic is not transfer"
        )
    return problems


def check_probes(spec: Spec) -> list[Issue]:
    targets = _targets(spec)
    issues: list[Issue] = []
    for game in spec.games:
        for probe in game["transfer_probes"]:
            for problem in probe_problems(game, probe, targets):
                issues.append(error("probe", f"game:{game['id']}", f"probe '{probe['id']}': {problem}"))
    return issues


def check_deep_coverage(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    targets = _targets(spec)
    games_by_skill: dict[str, list[Record]] = defaultdict(list)
    for game in spec.games:
        for skill in game["primary_skills"]:
            games_by_skill[skill].append(game)
    tasks_by_skill: dict[str, list[Record]] = defaultdict(list)
    for task in spec.transfer_tasks:
        for skill in task["skills"]:
            tasks_by_skill[skill].append(task)
    skills_with_rules = {rule["skill"] for rule in spec.assessment_rules}

    for skill in spec.skills:
        if not skill["deep_scope"]:
            continue
        skill_id = skill["id"]
        where = f"skill:{skill_id}"
        games = games_by_skill.get(skill_id, [])

        if not games:
            issues.append(error("deep-coverage", where, "no game has this skill as a primary skill"))
        if skill_id not in skills_with_rules:
            issues.append(error("deep-coverage", where, "has no assessment rule"))

        mechanics = {game["mechanic_id"] for game in games}
        mechanics |= {task["mechanic_id"] for task in tasks_by_skill.get(skill_id, [])}
        if len(mechanics) < 2:
            issues.append(error(
                "deep-coverage", where,
                f"covered by {len(mechanics)} distinct mechanic(s) {sorted(mechanics)}; needs at least two "
                "(two games, or one game plus a transfer task on a different mechanic)",
            ))

        has_valid_cross_game = any(
            probe["type"] == "cross_game"
            and probe["skill"] == skill_id
            and not probe_problems(game, probe, targets)
            for game in games
            for probe in game["transfer_probes"]
        )
        if not has_valid_cross_game:
            issues.append(error("deep-coverage", where, "has no valid cross_game transfer probe"))
    return issues
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `93 passed`.

- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add tools/validate
git commit -m "Add transfer probe and deep-coverage rules" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 8: Language pack and i18n rules

**Files:**
- Create: `tools/validate/nova_validate/langpack_rules.py`, `i18n_rules.py`
- Test: `tools/validate/tests/test_langpack_i18n_rules.py`

**Interfaces:**
- Consumes: `SLOTS`, `index_by_id` from `model`.
- Produces: `check_langpacks(spec)` (rule `langpack`); `check_i18n(spec)` (rule `i18n`).

- [ ] **Step 1: Write the failing test**

`tools/validate/tests/test_langpack_i18n_rules.py`:

```python
from nova_validate.i18n_rules import check_i18n
from nova_validate.langpack_rules import check_langpacks
from nova_validate.model import SLOTS
from tests.factory import get, make_spec, rules_of


def test_valid_factory_langpacks_pass():
    assert check_langpacks(make_spec()) == []


def test_skill_in_an_unknown_language_is_rejected():
    spec = make_spec()
    get(spec.skills, "lit.ar.letter.recognize-isolated")["language"] = "fr"
    issues = check_langpacks(spec)
    assert "langpack" in rules_of(issues)
    assert any("fr" in issue.message for issue in issues)


def test_contract_only_pack_cannot_have_skills():
    spec = make_spec()
    get(spec.langpacks, "ar")["status"] = "contract_only"
    issues = check_langpacks(spec)
    assert any("contract_only" in issue.message for issue in issues)


def test_declared_slots_must_match_skill_slots():
    spec = make_spec()
    get(spec.langpacks, "ar")["slots_filled"] = []
    issues = check_langpacks(spec)
    assert rules_of(issues) == {"langpack"}
    assert "does not match" in issues[0].message


def test_complete_pack_must_fill_every_slot():
    spec = make_spec()
    get(spec.langpacks, "ar")["status"] = "complete"
    issues = check_langpacks(spec)
    assert any("complete" in issue.message for issue in issues)


def test_complete_pack_filling_every_slot_passes():
    spec = make_spec()
    pack = get(spec.langpacks, "ar")
    pack["status"] = "complete"
    pack["slots_filled"] = list(SLOTS)
    for index, slot in enumerate(s for s in SLOTS if s != "letter_knowledge"):
        clone = dict(get(spec.skills, "lit.ar.letter.recognize-isolated"))
        clone["id"] = f"lit.ar.extra-{index}"
        clone["slot"] = slot
        clone["deep_scope"] = True
        spec.skills.append(clone)
    assert check_langpacks(spec) == []


def test_valid_factory_i18n_passes():
    assert check_i18n(make_spec()) == []


def test_missing_english_string_is_reported():
    spec = make_spec()
    del spec.i18n["en"]["skill.math.count.cardinality.name"]
    issues = check_i18n(spec)
    assert rules_of(issues) == {"i18n"}
    assert issues[0].where == "skill:math.count.cardinality"
    assert "'en'" in issues[0].message


def test_missing_arabic_string_is_reported():
    spec = make_spec()
    del spec.i18n["ar"]["game.math.bear-snacks.name"]
    issues = check_i18n(spec)
    assert issues[0].where == "game:game.math.bear-snacks"
    assert "'ar'" in issues[0].message


def test_blank_string_counts_as_missing():
    spec = make_spec()
    spec.i18n["ar"]["task.math.count-objects-at-home.name"] = "   "
    assert rules_of(check_i18n(spec)) == {"i18n"}


def test_null_value_counts_as_missing():
    spec = make_spec()
    spec.i18n["en"]["skill.math.count.cardinality.name"] = None
    assert rules_of(check_i18n(spec)) == {"i18n"}


def test_non_string_value_counts_as_missing():
    spec = make_spec()
    spec.i18n["ar"]["game.math.bear-snacks.name"] = 123
    assert rules_of(check_i18n(spec)) == {"i18n"}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/Scripts/python.exe -m pytest tests/test_langpack_i18n_rules.py -q`
Expected: collection error, `ModuleNotFoundError: No module named 'nova_validate.i18n_rules'`.

- [ ] **Step 3: Implement**

`tools/validate/nova_validate/langpack_rules.py`:

```python
"""Language pack rules: skills belong to a real pack, and packs fill the shared slots."""
from __future__ import annotations

from collections import defaultdict

from .model import SLOTS, Issue, Record, Spec, error, index_by_id


def check_langpacks(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    packs = index_by_id(spec.langpacks)
    skills_by_language: dict[str, list[Record]] = defaultdict(list)

    for skill in spec.skills:
        if skill["scope"] != "language-specific":
            continue
        language = skill["language"]
        if language not in packs:
            issues.append(error("langpack", f"skill:{skill['id']}", f"language '{language}' has no language pack"))
        else:
            skills_by_language[language].append(skill)

    for pack in spec.langpacks:
        where = f"langpack:{pack['id']}"
        pack_skills = skills_by_language.get(pack["id"], [])
        actual_slots = {skill["slot"] for skill in pack_skills if "slot" in skill}
        declared_slots = set(pack["slots_filled"])

        if pack["status"] == "contract_only" and pack_skills:
            issues.append(error("langpack", where, "is contract_only but has language-specific skills"))
        if declared_slots != actual_slots:
            issues.append(error(
                "langpack", where,
                f"slots_filled {sorted(declared_slots)} does not match the slots its skills fill {sorted(actual_slots)}",
            ))
        if pack["status"] == "complete":
            missing = sorted(set(SLOTS) - declared_slots)
            if missing:
                issues.append(error("langpack", where, f"is marked complete but does not fill slots {missing}"))
    return issues
```

`tools/validate/nova_validate/i18n_rules.py`:

```python
"""i18n rules: every key a record uses has a non-empty string in every launch language."""
from __future__ import annotations

from .model import Issue, Spec, error


def check_i18n(spec: Spec) -> list[Issue]:
    needed: list[tuple[str, str]] = []
    for skill in spec.skills:
        needed.append((f"skill:{skill['id']}", skill["name_key"]))
        needed.append((f"skill:{skill['id']}", skill["description_key"]))
    for game in spec.games:
        needed.append((f"game:{game['id']}", game["name_key"]))
    for task in spec.transfer_tasks:
        needed.append((f"transfer_task:{task['id']}", task["name_key"]))

    issues: list[Issue] = []
    for language, table in spec.i18n.items():
        for where, key in needed:
            value = table.get(key)
            if not isinstance(value, str) or not value.strip():
                issues.append(error("i18n", where, f"missing '{language}' string for key '{key}'"))
    return issues
```

- [ ] **Step 4: Run the tests to verify they pass**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `105 passed`.

- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add tools/validate
git commit -m "Add language pack and i18n rules" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 9: Report, CLI and end-to-end tests

**Files:**
- Create: `tools/validate/nova_validate/report.py`, `cli.py`, `__main__.py`
- Create: `tools/validate/README.md`
- Test: `tools/validate/tests/test_cli.py`

**Interfaces:**
- Consumes: every `check_*` function from Tasks 2-8, `load_spec` from Task 1.
- Produces: `cli.run_all(spec, schema_dir) -> list[Issue]` (schema and unique-id errors stop the run before semantic rules); `cli.main(argv=None) -> int` (0 when no errors, else 1); `report.evidence_table(spec) -> str`; `report.summary(spec) -> str`. Command: `python -m nova_validate [--data DIR] [--report] [--evidence-table]`.

- [ ] **Step 1: Write the failing test**

`tools/validate/tests/test_cli.py`:

```python
import shutil
from pathlib import Path

from nova_validate.cli import main, run_all
from nova_validate.report import evidence_table, summary
from tests.factory import errors_of, get, make_spec, rules_of, write_spec

SCHEMA_DIR = Path(__file__).resolve().parents[3] / "data" / "schema"


def write_data(tmp_path, spec):
    write_spec(spec, tmp_path)
    shutil.copytree(SCHEMA_DIR, tmp_path / "schema")
    return tmp_path


def test_valid_factory_spec_has_no_issues_at_all():
    assert run_all(make_spec(), SCHEMA_DIR) == []


def test_schema_errors_stop_semantic_rules():
    spec = make_spec()
    del spec.skills[0]["indicators"]
    spec.skills[1]["evidence_basis"] = "judgment"  # a semantic error that must not be reported yet
    assert rules_of(run_all(spec, SCHEMA_DIR)) == {"schema"}


def test_semantic_errors_from_every_family_are_collected():
    spec = make_spec()
    spec.skills[1]["evidence_basis"] = "judgment"
    del spec.i18n["en"]["skill.math.count.cardinality.name"]
    get(spec.assessment_rules, "rule.math.count.cardinality")["inputs"] = ["session_time"]
    found = rules_of(errors_of(run_all(spec, SCHEMA_DIR)))
    assert {"evidence-basis", "i18n", "engagement-signal"} <= found


def test_main_returns_zero_for_valid_data_on_disk(tmp_path, capsys):
    data = write_data(tmp_path, make_spec())
    assert main(["--data", str(data)]) == 0
    assert "0 error(s), 0 warning(s)" in capsys.readouterr().out


def test_main_returns_one_and_prints_errors(tmp_path, capsys):
    spec = make_spec()
    spec.skills[1]["evidence_basis"] = "judgment"
    data = write_data(tmp_path, spec)
    assert main(["--data", str(data)]) == 1
    out = capsys.readouterr().out
    assert "ERROR [evidence-basis]" in out
    assert "1 error(s)" in out


def test_warnings_do_not_fail_the_run(tmp_path, capsys):
    spec = make_spec()
    get(spec.games, "game.math.bear-snacks")["difficulty"]["rungs"][1]["values"]["distractors"] = 1
    data = write_data(tmp_path, spec)
    assert main(["--data", str(data)]) == 0
    assert "WARNING [difficulty-step]" in capsys.readouterr().out


def test_report_flag_prints_counts(tmp_path, capsys):
    data = write_data(tmp_path, make_spec())
    assert main(["--data", str(data), "--report"]) == 0
    out = capsys.readouterr().out
    assert "skills: 4 (deep_scope: 3)" in out
    assert "evidence_basis: empirical=1, framework=2, judgment=1" in out
    assert "prerequisite edges: 1 (cited: 0, design inference: 1)" in out
    assert "parameters: provisional=3, pilot_calibrated=0, validated=0" in out


def test_evidence_table_lists_every_entry():
    table = evidence_table(make_spec())
    assert table.splitlines()[0].startswith("| id | type | strength")
    assert "| ev.test.meta | meta_analysis | moderate | True |" in table
    assert len(table.splitlines()) == 2 + 3


def test_evidence_table_flag_prints_markdown(tmp_path, capsys):
    data = write_data(tmp_path, make_spec())
    assert main(["--data", str(data), "--evidence-table"]) == 0
    assert "| ev.test.design | design_inference | emerging |" in capsys.readouterr().out


def test_summary_counts_cited_edges():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [
        {"skill": "math.count.one-to-one-5", "evidence_refs": ["ev.test.meta"]}
    ]
    assert "cited: 1, design inference: 0" in summary(spec)


def test_report_flag_does_not_crash_on_schema_invalid_data(tmp_path, capsys):
    spec = make_spec()
    del spec.skills[0]["deep_scope"]
    data = write_data(tmp_path, spec)
    assert main(["--data", str(data), "--report"]) == 1
    out = capsys.readouterr().out
    assert "ERROR [schema]" in out
    assert "error(s)" in out
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `.venv/Scripts/python.exe -m pytest tests/test_cli.py -q`
Expected: collection error, `ModuleNotFoundError: No module named 'nova_validate.cli'`.

- [ ] **Step 3: Implement**

`tools/validate/nova_validate/report.py`:

```python
"""Human-readable summaries generated from the spec data."""
from __future__ import annotations

from collections import Counter

from .model import Spec


def evidence_table(spec: Spec) -> str:
    """Markdown table of every evidence entry, for chapter 01 (generated so it cannot drift)."""

    def cell(value: object) -> str:
        return str(value).replace("|", "\\|").replace("\n", " ")

    header = "| id | type | strength | verified | population | delivery | language | finding |"
    rule = "|---|---|---|---|---|---|---|---|"
    rows = [
        "| " + " | ".join(cell(entry[key]) for key in (
            "id", "evidence_type", "evidence_strength", "verified",
            "population", "delivery", "language", "finding",
        )) + " |"
        for entry in sorted(spec.evidence, key=lambda entry: entry["id"])
    ]
    return "\n".join([header, rule, *rows])


def summary(spec: Spec) -> str:
    basis = Counter(skill["evidence_basis"] for skill in spec.skills)
    edges = [edge for skill in spec.skills for edge in skill["prerequisites"]]
    cited = sum(1 for edge in edges if edge.get("evidence_refs"))
    status = Counter(parameter["status"] for parameter in spec.parameters)
    deep = sum(1 for skill in spec.skills if skill["deep_scope"])

    def counts(counter: Counter, names: tuple[str, ...]) -> str:
        return ", ".join(f"{name}={counter.get(name, 0)}" for name in names)

    return "\n".join([
        f"skills: {len(spec.skills)} (deep_scope: {deep})",
        f"  evidence_basis: {counts(basis, ('empirical', 'framework', 'judgment'))}",
        f"prerequisite edges: {len(edges)} (cited: {cited}, design inference: {len(edges) - cited})",
        f"games: {len(spec.games)}  transfer tasks: {len(spec.transfer_tasks)}  "
        f"assessment rules: {len(spec.assessment_rules)}",
        f"parameters: {counts(status, ('provisional', 'pilot_calibrated', 'validated'))}",
    ])
```

`tools/validate/nova_validate/cli.py`:

```python
"""Command line entry point: python -m nova_validate [--data DIR] [--report] [--evidence-table]."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .assessment_rules import check_assessment_rules
from .coverage_rules import check_deep_coverage, check_probes
from .evidence_rules import check_evidence_basis, check_evidence_entries
from .game_rules import check_games
from .graph_rules import check_skill_graph
from .i18n_rules import check_i18n
from .langpack_rules import check_langpacks
from .loader import load_spec
from .model import Issue, Spec
from .parameter_rules import check_parameters
from .report import evidence_table, summary
from .schema_rules import check_schemas, check_unique_ids

# Rules that assume every record already has the right shape.
SEMANTIC_CHECKS = (
    check_skill_graph,
    check_evidence_entries,
    check_evidence_basis,
    check_parameters,
    check_assessment_rules,
    check_games,
    check_probes,
    check_deep_coverage,
    check_langpacks,
    check_i18n,
)


def run_all(spec: Spec, schema_dir: Path) -> list[Issue]:
    issues = check_schemas(spec, schema_dir) + check_unique_ids(spec)
    if any(issue.level == "error" for issue in issues):
        return issues  # semantic rules assume valid shapes, so stop here
    for check in SEMANTIC_CHECKS:
        issues.extend(check(spec))
    return issues


def default_data_root() -> Path:
    # tools/validate/nova_validate/cli.py -> repository root is three levels above the package
    return Path(__file__).resolve().parents[3] / "data"


def main(argv: list[str] | None = None) -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass  # not a real text stream (e.g. captured in a test)

    parser = argparse.ArgumentParser(prog="nova_validate", description="Validate the Nova curriculum data.")
    parser.add_argument("--data", type=Path, default=default_data_root(), help="data directory (default: <repo>/data)")
    parser.add_argument("--report", action="store_true", help="print counts after validating")
    parser.add_argument("--evidence-table", action="store_true", help="print the evidence table as Markdown and exit")
    args = parser.parse_args(argv)

    spec = load_spec(args.data)
    if args.evidence_table:
        print(evidence_table(spec))
        return 0

    issues = run_all(spec, args.data / "schema")
    for issue in issues:
        print(issue)
    error_count = sum(1 for issue in issues if issue.level == "error")
    if args.report and not any(issue.rule in ("schema", "unique-id") for issue in issues):
        print(summary(spec))
    print(f"{error_count} error(s), {len(issues) - error_count} warning(s)")
    return 1 if error_count else 0
```

`tools/validate/nova_validate/__main__.py`:

```python
import sys

from .cli import main

sys.exit(main())
```

`tools/validate/README.md`:

````markdown
# Nova spec validator

Checks the curriculum data in `../../data` against the rules in
`docs/superpowers/specs/2026-09-21-nova-curriculum-design.md`.

```bash
python -m venv .venv
.venv/Scripts/python.exe -m pip install -r requirements.txt
.venv/Scripts/python.exe -m pytest -q                 # the validator's own tests
.venv/Scripts/python.exe -m nova_validate --report    # validate the data
.venv/Scripts/python.exe -m nova_validate --evidence-table   # Markdown table for chapter 01
```

Exit code is 1 when any error is found. Warnings do not fail the run.
````

- [ ] **Step 4: Run the full test suite and the CLI**

Run: `.venv/Scripts/python.exe -m pytest -q`
Expected: `116 passed`.

Run: `.venv/Scripts/python.exe -m nova_validate --report`
Expected (data dir has only the schemas so far):

```
skills: 0 (deep_scope: 0)
  evidence_basis: empirical=0, framework=0, judgment=0
prerequisite edges: 0 (cited: 0, design inference: 0)
games: 0  transfer tasks: 0  assessment rules: 0
parameters: provisional=0, pilot_calibrated=0, validated=0
0 error(s), 0 warning(s)
```

- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add tools/validate
git commit -m "Add report, CLI and end-to-end tests" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Phase 2: Vocabularies and the worked example

### Task 10: Vocabularies, default parameters and the counting slice

This task creates real data files. They are the templates every later content task copies, so copy them exactly. They validate with zero errors as written.

**Files:**
- Create: `data/mechanics.yaml`, `data/signals.yaml`
- Create: `data/langpacks/langpacks.yaml`
- Create: `data/parameters/defaults.yaml`
- Create: `data/evidence/design-inferences.yaml`
- Create: `data/skills/math/counting.yaml`, `data/games/math/counting.yaml`, `data/transfer_tasks/math-counting.yaml`, `data/assessment/math-counting.yaml`
- Create: `data/i18n/en.yaml`, `data/i18n/ar.yaml`

**Interfaces:**
- Produces: the mechanic ids, signal ids (learning: `accuracy`, `response_time`, `hints_used`, `retries`, `error_type`, `adult_assist`, `self_correction`; engagement: `session_time`, `completion`, `streak`, `stars`, `return_visit`), parameter ids `param.default.*`, language pack ids `ar`, `en`, `zh`, `hi`, and the counting records that later tasks extend.

- [ ] **Step 1: Create the vocabularies**

`data/mechanics.yaml`:

```yaml
# Controlled mechanic vocabulary. A game or transfer task names exactly one mechanic_id.
# "Different mechanic" in the transfer rules means a different id from this list, so add a
# new entry only when the interaction really differs, never for a reskin.
- id: sequence-recall
  description: Watch a short sequence of items, then reproduce it in order.
- id: position-recall
  description: Watch items appear in places, then say or tap where each one was.
- id: match-pairs
  description: Turn over or reveal items to find matching pairs.
- id: sort-by-rule
  description: Put items into groups according to one stated rule (colour, shape, size).
- id: switch-sort-rule
  description: Sort by one rule, then sort the same items by a different rule after a cue.
- id: go-no-go
  description: Act on one kind of signal and hold back on another.
- id: wait-then-act
  description: Hold still for a stated delay before acting.
- id: drag-to-count
  description: Drag objects one at a time into a container until a requested number is reached.
- id: tap-to-count
  description: Tap each object once while the number words are spoken.
- id: match-symbol-to-quantity
  description: Pair a numeral with the group that has that many items, or the reverse.
- id: compare-quantities
  description: Choose the group with more, fewer or the same number of items.
- id: number-line-place
  description: Place a numeral or object at the right position on a number line.
- id: pattern-continue
  description: Extend a repeating or growing pattern with the next items.
- id: puzzle-assemble
  description: Fit pieces together to complete a shape or picture.
- id: catch-target
  description: Tap the target among moving or falling items when it matches a spoken cue.
- id: sound-match
  description: Choose the picture or item whose sound matches a spoken sound.
- id: rhyme-select
  description: Choose the item that rhymes with a spoken word.
- id: blend-sounds
  description: Hear separate sounds or syllables and pick the word they make.
- id: segment-sounds
  description: Hear a word and tap once for each sound or syllable in it.
- id: letter-trace
  description: Trace a letter shape with a finger, following the stroke order.
- id: letter-match
  description: Pair two forms of the same letter, or a letter with its name or sound.
- id: print-hunt
  description: Find a named letter or word in real printed material, with an adult.
- id: physical-counting
  description: Count real objects at home or in class, with an adult recording the result.
- id: physical-build
  description: Build something from real blocks or materials to a stated specification.
- id: physical-hunt
  description: Find real objects that match a stated property, then bring or show them.
- id: story-choice
  description: Listen to a short story and choose what happens next or why.
- id: emotion-match
  description: Match a face, situation or voice to the emotion it shows.
- id: free-draw
  description: Make an open-ended drawing or creation with no single correct answer.
- id: physical-freeze
  description: Move or freeze on a spoken or musical signal, with an adult (freeze dance, Simon says).
- id: physical-sort
  description: Sort real objects into groups by a stated rule, with an adult.
- id: retell
  description: Retell a story or a sequence of events in order, aloud, to an adult.
- id: oral-sound-game
  description: Adult-led spoken game about sounds in words, with no screen (for example, I spy with the first sound).
```

`data/signals.yaml`:

```yaml
# Signal vocabulary. Every logged signal is tagged learning or engagement (spec, principle 3).
# Assessment rules may consume only learning signals; the validator rejects any rule that
# names an engagement signal. Engagement signals exist for product health, never for mastery.
- id: accuracy
  kind: learning
  description: Share of responses that are correct at the current rung.
- id: response_time
  kind: learning
  description: Time from prompt to response, used only alongside accuracy.
- id: hints_used
  kind: learning
  description: Number of hints the child received on a trial.
- id: retries
  kind: learning
  description: Number of attempts before a correct response.
- id: error_type
  kind: learning
  description: Category of each error, defined per game, used for diagnosis.
- id: adult_assist
  kind: learning
  description: Whether an adult helped, as reported in the app or observed.
- id: self_correction
  kind: learning
  description: The child notices and fixes their own error without a prompt.
- id: session_time
  kind: engagement
  description: Minutes spent in the app.
- id: completion
  kind: engagement
  description: Whether a level or game was finished.
- id: streak
  kind: engagement
  description: Consecutive days or sessions played.
- id: stars
  kind: engagement
  description: Rewards collected in the game.
- id: return_visit
  kind: engagement
  description: Whether the child comes back to a game.
```

- [ ] **Step 2: Create the language packs and default parameters**

`data/langpacks/langpacks.yaml`:

```yaml
# Language packs. status moves in_progress -> complete only when every shared slot is filled.
# zh and hi are contract_only: they document what a pack must supply and what differs, and
# hold no skills yet.
- id: ar
  name: Arabic
  status: in_progress
  script:
    direction: rtl
    joining: true
    diacritics: true
    tonal: false
    notes: Cursive script; each letter has isolated, initial, medial and final forms; short vowels are optional diacritics (harakat).
  slots_filled: []
  instruction_voice: undecided (Modern Standard Arabic or a dialect such as Egyptian; see chapter 05)
- id: en
  name: English
  status: in_progress
  script:
    direction: ltr
    joining: false
    diacritics: false
    tonal: false
    notes: Alphabetic with an opaque spelling system; uppercase and lowercase letter forms.
  slots_filled: []
  instruction_voice: English
- id: zh
  name: Chinese (Mandarin)
  status: contract_only
  script:
    direction: ltr
    joining: false
    diacritics: false
    tonal: true
    notes: Logographic characters built from strokes and radicals; pinyin is a separate phonetic layer; four tones plus neutral.
  slots_filled: []
  instruction_voice: undecided
- id: hi
  name: Hindi
  status: contract_only
  script:
    direction: ltr
    joining: false
    diacritics: true
    tonal: false
    notes: Devanagari abugida; consonants carry an inherent vowel, changed by matras; conjunct consonants.
  slots_filled: []
  instruction_voice: undecided
```

`data/parameters/defaults.yaml`:

```yaml
# Default assessment and progression parameters. Every value is PROVISIONAL: a starting
# point chosen by design, not a finding, and none is scientifically validated. Chapter 08
# describes the pilot that will calibrate them. Add a skill- or cluster-specific parameter
# only when a default is clearly wrong for it, and keep it provisional too.
- id: param.default.min-trials
  value: 6
  unit: trials
  status: provisional
  basis: design_inference
  rationale: A handful of trials is the least that lets accuracy mean anything; the number is a design guess.
  calibration_plan: Choose from pilot data by finding where the mastery estimate stops changing as trials are added.
- id: param.default.emerging-accuracy
  value: 0.4
  unit: proportion of correct responses
  status: provisional
  basis: design_inference
  rationale: Above what guessing gives on a small choice set, so some real understanding is plausible.
  calibration_plan: Compare with chance level per game and with an adult-rated criterion in the pilot.
- id: param.default.developing-accuracy
  value: 0.6
  unit: proportion of correct responses
  status: provisional
  basis: design_inference
  rationale: Clearly above chance but still error-prone.
  calibration_plan: Set from the pilot distribution of accuracy in children an adult rates as developing.
- id: param.default.secure-accuracy
  value: 0.85
  unit: proportion of correct responses
  status: provisional
  basis: design_inference
  rationale: High and consistent accuracy is the working meaning of secure.
  calibration_plan: Calibrate against adult-rated mastery and retention on a delayed probe in the pilot.
- id: param.default.secure-max-hints-per-trial
  value: 0.2
  unit: hints per trial
  status: provisional
  basis: design_inference
  rationale: Secure means little support is needed, so hints must be rare.
  calibration_plan: Set from pilot data on how hint use relates to success on an unsupported probe.
- id: param.default.transfer-pass-accuracy
  value: 0.7
  unit: proportion of correct responses
  status: provisional
  basis: design_inference
  rationale: A transfer probe is unfamiliar, so the pass mark is set a little below the secure mark.
  calibration_plan: Set from pilot data on accuracy on probes among children rated secure and not secure.
- id: param.default.advance-accuracy
  value: 0.8
  unit: proportion of correct responses over the last min-trials
  status: provisional
  basis: design_inference
  rationale: Move to the next rung when the current one is mostly under control.
  calibration_plan: Tune in the pilot to keep children in a productive band without frustration or boredom.
- id: param.default.retreat-accuracy
  value: 0.5
  unit: proportion of correct responses over the last min-trials
  status: provisional
  basis: design_inference
  rationale: Step back a rung when a child is failing about as often as succeeding.
  calibration_plan: Tune in the pilot alongside the advance threshold.
- id: param.default.delayed-probe-interval-days
  value: 7
  unit: days
  status: provisional
  basis: design_inference
  rationale: A week is long enough that success is not just short-term recall, and short enough to schedule.
  calibration_plan: Compare 3, 7 and 14 day intervals in the pilot for retention signal and drop-out.
```

- [ ] **Step 3: Create the design-inference evidence and the counting slice**

`data/evidence/design-inferences.yaml`:

```yaml
# Design inferences: Nova's own working assumptions. They are judgment-class evidence, capped
# at 'emerging', and never count as empirical support. The research task may replace one with
# verified empirical or framework evidence; then update the skill or game that cites it.
- id: ev.design.counting-progression
  title: Working order for early counting skills
  citation: Nova design decision, 2026-09
  verified: false
  evidence_type: design_inference
  evidence_strength: emerging
  population: children 3-6 years
  delivery: not_applicable
  language: multi
  finding: Nova orders counting as one-to-one correspondence, then cardinality (the last number counted is the total). This is a working assumption, to be checked against the early-counting literature.
  limits: Not tested by Nova; ordering may differ for individual children.
- id: ev.design.drag-to-count-mechanic
  title: Dragging objects one at a time to support counting
  citation: Nova design decision, 2026-09
  verified: false
  evidence_type: design_inference
  evidence_strength: emerging
  population: children 3-5 years
  delivery: digital
  language: multi
  finding: Moving one object per number word makes one-to-one correspondence visible and physical on a screen. This is an assumption; Nova has not tested that it builds the skill.
  limits: No evidence that a screen drag transfers to counting real objects; the transfer probes test exactly that.
- id: ev.design.match-symbol-mechanic
  title: Pairing numerals with quantities to link symbol and amount
  citation: Nova design decision, 2026-09
  verified: false
  evidence_type: design_inference
  evidence_strength: emerging
  population: children 4-6 years
  delivery: digital
  language: multi
  finding: Pairing a numeral with a group of that size links the symbol to the amount. This is an assumption; Nova has not tested it.
  limits: Children may learn the pairing task without learning the concept; the transfer probes test this.
```

`data/skills/math/counting.yaml`:

```yaml
- id: math.count.one-to-one-5
  domains: [math]
  name_key: skill.math.count.one-to-one-5.name
  description_key: skill.math.count.one-to-one-5.description
  prerequisites: []
  age_range: [3, 4]
  indicators:
    - Touches or moves one object for each number word said
    - Does not skip or double-count objects in a group of up to 5
  evidence_basis: judgment
  evidence_refs: [ev.design.counting-progression]
  scope: universal
  deep_scope: true
- id: math.count.cardinality
  domains: [math]
  name_key: skill.math.count.cardinality.name
  description_key: skill.math.count.cardinality.description
  prerequisites:
    - skill: math.count.one-to-one-5
  age_range: [4, 5]
  indicators:
    - Says the last number counted when asked how many
    - Answers "how many" without recounting when nothing was added or removed
  evidence_basis: judgment
  evidence_refs: [ev.design.counting-progression]
  scope: universal
  deep_scope: true
```

`data/games/math/counting.yaml`:

```yaml
- id: game.math.bear-apples
  name_key: game.math.bear-apples.name
  age_range: [3, 5]
  primary_skills: [math.count.one-to-one-5, math.count.cardinality]
  secondary_skills: []
  objective: Give the bear exactly the number of apples it asks for.
  mechanic_id: drag-to-count
  mechanic: The bear asks for a number of apples; the child drags apples onto its plate one at a time while each number is spoken.
  evidence_basis: judgment
  evidence_refs: [ev.design.drag-to-count-mechanic]
  difficulty:
    varied: [item_complexity, distractors]
    anchors:
      item_complexity: ["requests of 1 to 3", "requests of 1 to 5"]
      distractors: ["only the requested apples on the table", "extra apples on the table"]
    rungs:
      - id: r1
        values: {item_complexity: 0, distractors: 0, working_memory_load: 0, rule_complexity: 0, abstraction: 0, cognitive_load: 0, independence: 0}
      - id: r2
        values: {item_complexity: 1, distractors: 0, working_memory_load: 0, rule_complexity: 0, abstraction: 0, cognitive_load: 0, independence: 0}
      - id: r3
        values: {item_complexity: 1, distractors: 1, working_memory_load: 0, rule_complexity: 0, abstraction: 0, cognitive_load: 0, independence: 0}
  scaffolding:
    hints:
      - Each apple briefly lights up as its number is spoken.
      - The bear points at the plate and says the running count.
    adult_prompt: "After the child finishes, ask: how many apples does the bear have? Let them answer before you say it."
  signals: [accuracy, hints_used, retries, error_type, completion]
  progression:
    advance_parameter: param.default.advance-accuracy
    retreat_parameter: param.default.retreat-accuracy
  transfer_probes:
    - id: probe.one-to-one-at-home
      type: cross_game
      delayed: false
      skill: math.count.one-to-one-5
      mechanic_id: physical-counting
      task_ref: task.math.count-objects-at-home
      changes: From screen apples to real objects at home, counted with a person.
      preserved: One number word for each object, in groups of up to 5.
    - id: probe.cardinality-at-home
      type: cross_game
      delayed: false
      skill: math.count.cardinality
      mechanic_id: physical-counting
      task_ref: task.math.count-objects-at-home
      changes: From screen apples to real objects at home, and the adult asks "how many?".
      preserved: Stating the last number counted as the total.
    - id: probe.cardinality-later
      type: cross_context
      delayed: true
      skill: math.count.cardinality
      mechanic_id: physical-counting
      task_ref: task.math.count-objects-at-home
      changes: Same real-object counting, presented about a week after the child last played.
      preserved: Stating the last number counted as the total.
  offline_extension: Ask the child to set the table with exactly the right number of spoons for the people eating.
  language_dependencies: []
- id: game.math.number-match
  name_key: game.math.number-match.name
  age_range: [4, 6]
  primary_skills: [math.count.cardinality]
  secondary_skills: []
  objective: Match a numeral card to the group that has that many items.
  mechanic_id: match-symbol-to-quantity
  mechanic: A numeral appears with several groups of objects; the child taps the group with that many items.
  evidence_basis: judgment
  evidence_refs: [ev.design.match-symbol-mechanic]
  difficulty:
    varied: [abstraction, distractors]
    anchors:
      abstraction: ["numeral to dot groups", "numeral to groups of mixed pictures"]
      distractors: ["two groups to choose from", "three groups to choose from"]
    rungs:
      - id: r1
        values: {item_complexity: 0, distractors: 0, working_memory_load: 0, rule_complexity: 0, abstraction: 0, cognitive_load: 0, independence: 0}
      - id: r2
        values: {item_complexity: 0, distractors: 0, working_memory_load: 0, rule_complexity: 0, abstraction: 1, cognitive_load: 0, independence: 0}
      - id: r3
        values: {item_complexity: 0, distractors: 1, working_memory_load: 0, rule_complexity: 0, abstraction: 1, cognitive_load: 0, independence: 0}
  scaffolding:
    hints:
      - The groups are highlighted one at a time and counted aloud.
    adult_prompt: Ask the child to count the group they chose out loud before they confirm.
  signals: [accuracy, response_time, hints_used, error_type]
  progression:
    advance_parameter: param.default.advance-accuracy
    retreat_parameter: param.default.retreat-accuracy
  transfer_probes: []
  language_dependencies: []
```

`data/transfer_tasks/math-counting.yaml`:

```yaml
- id: task.math.count-objects-at-home
  name_key: task.math.count-objects-at-home.name
  age_range: [3, 5]
  skills: [math.count.one-to-one-5, math.count.cardinality]
  mechanic_id: physical-counting
  description: An adult names a set of real objects (for example, spoons on the table); the child counts them aloud, then the adult asks how many there are.
  signals: [accuracy, adult_assist, error_type]
  scoring: The adult marks, in the app, whether each object got one number word and whether the child stated the total without recounting.
```

`data/assessment/math-counting.yaml`:

```yaml
- id: rule.math.count.one-to-one-5
  skill: math.count.one-to-one-5
  inputs: [accuracy, hints_used, error_type, adult_assist]
  state_criteria:
    emerging:
      description: At least min-trials responses logged and accuracy above the emerging threshold, at any support level.
      parameters: [param.default.min-trials, param.default.emerging-accuracy]
      requires_dimensions: [performance]
    developing:
      description: Accuracy above the developing threshold, with hints still in use.
      parameters: [param.default.min-trials, param.default.developing-accuracy]
      requires_dimensions: [performance]
    secure:
      description: Accuracy above the secure threshold with hints and adult help rare, over at least min-trials responses.
      parameters: [param.default.min-trials, param.default.secure-accuracy, param.default.secure-max-hints-per-trial]
      requires_dimensions: [performance, independence]
    transfer:
      description: Secure, plus a passed cross_game or cross_context probe at or above the transfer pass mark. A passed delayed probe raises confidence and does not change the state.
      parameters: [param.default.transfer-pass-accuracy, param.default.delayed-probe-interval-days]
      requires_dimensions: [transfer]
- id: rule.math.count.cardinality
  skill: math.count.cardinality
  inputs: [accuracy, hints_used, error_type, adult_assist]
  state_criteria:
    emerging:
      description: At least min-trials responses logged and accuracy above the emerging threshold, at any support level.
      parameters: [param.default.min-trials, param.default.emerging-accuracy]
      requires_dimensions: [performance]
    developing:
      description: Accuracy above the developing threshold, with hints still in use.
      parameters: [param.default.min-trials, param.default.developing-accuracy]
      requires_dimensions: [performance]
    secure:
      description: Accuracy above the secure threshold with hints and adult help rare, over at least min-trials responses.
      parameters: [param.default.min-trials, param.default.secure-accuracy, param.default.secure-max-hints-per-trial]
      requires_dimensions: [performance, independence]
    transfer:
      description: Secure, plus a passed cross_game or cross_context probe at or above the transfer pass mark. A passed delayed probe raises confidence and does not change the state.
      parameters: [param.default.transfer-pass-accuracy, param.default.delayed-probe-interval-days]
      requires_dimensions: [transfer]
```

- [ ] **Step 4: Create the i18n strings**

`data/i18n/en.yaml`:

```yaml
skill.math.count.one-to-one-5.name: Count up to 5, one object at a time
skill.math.count.one-to-one-5.description: Matches one number word to each object when counting a group of up to 5.
skill.math.count.cardinality.name: The last number is the total
skill.math.count.cardinality.description: Understands that the last number counted tells how many there are.
game.math.bear-apples.name: Bear's Apples
game.math.number-match.name: Number Match
task.math.count-objects-at-home.name: Count things at home
```

`data/i18n/ar.yaml`:

```yaml
skill.math.count.one-to-one-5.name: العدّ حتى ٥ شيئًا شيئًا
skill.math.count.one-to-one-5.description: يربط كل كلمة عدد بشيء واحد عند عدّ مجموعة تصل إلى ٥ أشياء.
skill.math.count.cardinality.name: آخر رقم هو العدد الكلي
skill.math.count.cardinality.description: يفهم أن آخر رقم يُعدّ يدلّ على عدد الأشياء كلها.
game.math.bear-apples.name: تفاحات الدبّ
game.math.number-match.name: طابِق الرقم
task.math.count-objects-at-home.name: عُدّ أشياء في البيت
```

- [ ] **Step 5: Validate**

Run (from `tools/validate`): `.venv/Scripts/python.exe -m nova_validate --report`
Expected:

```
skills: 2 (deep_scope: 2)
  evidence_basis: empirical=0, framework=0, judgment=2
prerequisite edges: 1 (cited: 0, design inference: 1)
games: 2  transfer tasks: 1  assessment rules: 2
parameters: provisional=9, pilot_calibrated=0, validated=0
0 error(s), 0 warning(s)
```

- [ ] **Step 6: Commit**

```bash
cd /d/hamada/nova
git add data
git commit -m "Add vocabularies, default parameters and counting worked example" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Phase 3: Research and framework chapters

### Task 11: Verify sources and write the evidence entries

**Files:**
- Create: `data/evidence/programs.yaml`, `data/evidence/guided-play-and-games.yaml`, `data/evidence/math.yaml`, `data/evidence/literacy.yaml`, `data/evidence/executive-function-and-transfer.yaml`, `data/evidence/digital-and-screens.yaml`, `data/evidence/social-emotional-and-spatial.yaml`
- Create: `docs/curriculum/research-log.md`
- Modify: `data/skills/math/counting.yaml`, `data/games/math/counting.yaml` (only if verified evidence replaces a design inference)

**Interfaces:**
- Produces: evidence ids of the form `ev.<topic>.<author-or-body>-<year>`, for example `ev.guided-play.skene-2022`. Later tasks cite these ids in `evidence_refs` and in chapter text as `[ev.id]`.

This task is research, not code. The web tools are deferred, so first load them: `ToolSearch` with `select:WebSearch,WebFetch`.

**The rule for every entry:** open the primary source (the journal page, the publisher, DOI, or the programme's own documentation) and confirm that the type, population, finding and limits you record are what it says. Only then set `verified: true`. If you cannot open or confirm a source, do not record it as empirical or framework evidence; drop it, or record the underlying assumption as `design_inference`. If an important source is a type the closed list lacks (for example a single observational study), do not force it into a wrong type; note it in `research-log.md` and raise a spec change with the user.

**Field guidance (shape only; every value comes from the source you opened):**

```yaml
- id: ev.<topic>.<author-or-body>-<year>
  title: <the paper or document title>
  citation: <authors, year, journal or publisher, volume/pages>
  url: <DOI or stable URL you actually opened>
  verified: true
  evidence_type: <one of the eight types, chosen by what the source IS>
  evidence_strength: <emerging | moderate | strong, by the rubric in the spec (3.6)>
  population: <who was studied, with ages>
  delivery: <teacher_led | digital | mixed | home | not_applicable>
  language: <en | ar | multi | ...>
  finding: <what it found, with the effect stated honestly>
  limits: <what it does not show; mixed or small effects, indirectness to Nova>
```

Strength rubric (from the spec): weigh quality, consistency across studies, and directness (age, outcome, digital versus teacher-led delivery, language). English or other-population findings are not assumed to hold for Arabic-speaking children. Do not rate a source `strong` because of its type alone.

- [ ] **Step 1: Load the web tools and read the spec section 3.6**

- [ ] **Step 2: Research and record, one topic group per commit**

Work through each row. For every row record what you found in the file named, and log the outcome.

| Topic | File | What to find and check |
|---|---|---|
| Programme frameworks | `programs.yaml` | HighScope (its eight content areas; Plan-Do-Review) and Tools of the Mind (executive function, make-believe play): use the programme's own documentation as `developmental_framework` or `program_evidence`. Check what controlled evaluations exist for Tools of the Mind and record honestly whether effects were positive, mixed or null. Harvard Center on the Developing Child's executive-function framework (working memory, inhibitory control, cognitive flexibility) as `developmental_framework`. Montessori, Reggio Emilia and Creative Curriculum: record what is documented and what evidence exists; do not overstate. |
| Guided play | `guided-play-and-games.yaml` | The brief cites a 2022 systematic review and meta-analysis of guided play in *Child Development* (Skene et al.), described as 39 studies with benefits over direct instruction for some maths, shape-knowledge, task-switching and spatial-vocabulary outcomes. Open it; confirm the study count, the outcomes and the direction. Record what it actually says. |
| Game-based learning, early childhood | `guided-play-and-games.yaml` | The brief cites a 2024 systematic review and meta-analysis in *Frontiers in Psychology* (10.3389/fpsyg.2024.1307881). Confirm the outcomes (cognitive, social, emotional, motivation, engagement), the claim that puzzle games had larger cognitive effects, and the role of adult guidance. |
| Early maths interventions | `math.yaml` | The brief cites (a) a 2026 three-level meta-analysis of pre-primary maths interventions (intentional teaching and exploratory play; described as 74 studies; ScienceDirect S1747938X26000692) and (b) a 2026 systematic review of 101 interventions for ages 3-6 in 25 countries (ERIC EJ1510312; described as over 90% positive, with weak transfer to broader maths). Open both; confirm every number, and record the transfer limitation, which matters for the Transfer state. |
| Phonological awareness | `literacy.yaml` | The brief cites, for a small overall effect on phonological awareness, an item whose title is "Combined Language and Code Emergent Literacy Intervention for At-Risk Preschool Children: A Systematic Meta-Analytic Review" (*Child Development*, 2025, 10.1111/cdev.14252). That title is not obviously a phonological-awareness meta-analysis. Open it and record only what it shows. Find the correct source for the phonological-awareness claim, or drop the claim. Also record the National Early Literacy Panel (2008) report as a systematic review of predictors of later reading. |
| Arabic early literacy | `literacy.yaml` | Find and verify sources on Arabic literacy acquisition (letter forms and positional shapes, diacritics, phonological awareness in Arabic, and the effect of the gap between spoken dialect and written Modern Standard Arabic). Record each as the type it truly is. Most will be observational; if so, see the rule above about types. |
| English early literacy | `literacy.yaml` | The National Early Literacy Panel report and one or two syntheses on phonics and phonemic awareness instruction. Verify and record. |
| Executive function and transfer | `executive-function-and-transfer.yaml` | Reviews and meta-analyses on whether training executive function or working memory transfers beyond the trained task (for example Diamond and Lee 2011 in *Science*; Melby-Lervag and Hulme on working-memory training; Sala and Gobet on far transfer). Verify each and record the near/far transfer findings honestly. Also a transfer framework (for example Barnett and Ceci 2002). These support the Transfer dimension. |
| Digital learning and screens | `digital-and-screens.yaml` | Hirsh-Pasek and colleagues (2015) on educational apps, as `developmental_framework`. The WHO (2019) guidelines on physical activity, sedentary behaviour and sleep for children under 5, and the American Academy of Pediatrics guidance, as `expert_consensus`. Verify the exact recommendations. |
| Social-emotional and spatial | `social-emotional-and-spatial.yaml` | CASEL's framework (`developmental_framework`) and one meta-analysis of school-based social-emotional programmes; one meta-analysis on the malleability of spatial skills and one source linking early spatial skill to maths. Verify each. |

- [ ] **Step 3: Write `docs/curriculum/research-log.md`**

A table with one row per citation from the original brief (eight of them: HighScope, Tools of the Mind, Harvard Center, the 2024 game-based learning review, the 2022 guided-play review, the 2026 maths meta-analysis, the 2026 maths systematic review, and the phonological-awareness item). Columns: what the brief claimed; what the source actually says; outcome (`confirmed`, `corrected`, `dropped`); the evidence id recorded, if any. This log is the honest record that the brief's citations were checked and not simply trusted.

- [ ] **Step 4: Upgrade the counting slice if warranted**

If a verified source now supports the counting ordering, add its id to `evidence_refs` in `data/skills/math/counting.yaml`, and set `evidence_basis` to whatever the precedence rule now gives. Do the same for a game whose mechanic has verified support. Leave the design inference in place if not.

- [ ] **Step 5: Validate and commit**

Run: `.venv/Scripts/python.exe -m nova_validate --report`
Expected: `0 error(s)`. Every non-judgment entry has `verified: true`; no `design_inference` is rated above `emerging`.

```bash
cd /d/hamada/nova
git add data docs
git commit -m "Add verified evidence entries and research log" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 12: Chapters 01 and 02

**Files:**
- Create: `docs/curriculum/01-research-foundation.md`, `docs/curriculum/02-developmental-framework.md`

**Interfaces:**
- Consumes: the evidence ids from Task 11 and the generated table (`python -m nova_validate --evidence-table`).

Every factual claim in these chapters cites an evidence id in square brackets, like `[ev.guided-play.skene-2022]`. A claim with no supporting entry is either dropped or written as an explicit design decision ("Nova's assumption"). The check in Step 3 fails on any bracketed id that does not exist.

- [ ] **Step 1: Write chapter 01, the research foundation**

Sections, in order:
1. *Purpose and honesty rules.* What "evidence-informed" means here; that expert judgment and design inference are not empirical evidence; that the brief's citations were checked (link `research-log.md`).
2. *Evidence types and strength.* The eight types and their three classes (empirical, framework, judgment), the strength scale, the caps, and the rubric (quality, consistency, directness). State that type never implies strength.
3. *How basis is computed.* The precedence rule, with one worked example for each of the three outcomes, and the reporting consequence ("evidence-based" versus "informed by").
4. *Programmes matrix.* A table with one row each for Montessori, HighScope, Tools of the Mind, Reggio Emilia, Creative Curriculum and the Harvard EF materials. Columns: what it is; what kind of evidence exists (type, honest strength); what Nova adopts; what Nova leaves out; why.
5. *The evidence table.* Paste the output of `.venv/Scripts/python.exe -m nova_validate --evidence-table` (run from `tools/validate`).
6. *Honest limits.* The small, mixed or non-transferring findings, stated plainly, and how each shapes the design (the Transfer dimension; the rule that in-game success is not learning).

- [ ] **Step 2: Write chapter 02, the developmental framework**

Sections, in order:
1. *The twelve domains.* One paragraph each for cognitive, executive function, language and literacy, math, problem solving, memory, attention, visual-spatial, fine motor, social-emotional, creativity and science/exploration: what it covers and what its skills look like across ages 2-8.
2. *Age stages.* The table Discovery (2-3), Foundation (3-4), Early Learning (4-5), School Readiness (5-6), Early Academic (6-7), Advanced Foundation (7-8), with the explicit statement that stages describe typical ranges and never gate content; a worked example of one child at different levels in different domains.
3. *Core principles.* The six principles from spec section 2, verbatim in meaning, with their consequences.
4. *Guided play.* Play plus objective plus scaffolding plus progression; Plan-Do-Review as a design pattern for games; adult scaffolding prompts; cite the evidence with its limits.
5. *Physical and offline play.* The digital-to-physical pattern (find something round; build a tower of 5), and why the product is not screen-only; cite the screen guidance evidence.

- [ ] **Step 3: Check every citation in the chapters resolves**

Run from `tools/validate`:

```bash
.venv/Scripts/python.exe - <<'EOF'
import re, pathlib
from nova_validate.loader import load_spec
ids = {e["id"] for e in load_spec(pathlib.Path("../../data")).evidence}
bad = [(p.name, m) for p in pathlib.Path("../../docs/curriculum").glob("*.md")
       for m in re.findall(r"\[(ev\.[a-z0-9._-]+)\]", p.read_text(encoding="utf-8")) if m not in ids]
print("unknown evidence ids:", bad)
raise SystemExit(1 if bad else 0)
EOF
```

Expected: `unknown evidence ids: []` and exit code 0.

- [ ] **Step 4: Commit**

```bash
cd /d/hamada/nova
git add docs
git commit -m "Add chapters 01 and 02: research foundation and developmental framework" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Phase 4: Skill clusters

The clusters below list skill ids, ages and prerequisites. The lists are the intended shape; if research (Task 11) shows an ordering is wrong, change the table entry and say why in the commit message. Ids in `prerequisites` must exist. The validator decides which skills must be `deep_scope: true`; do not decide by eye.

### Task 13: Executive function, memory and attention

**Files:**
- Create: `data/skills/executive_function/*.yaml`, `data/skills/memory/*.yaml`, `data/skills/attention/*.yaml`
- Create: `data/games/executive_function/*.yaml`, `data/games/memory/*.yaml`, `data/transfer_tasks/executive-function.yaml`, `data/assessment/executive-function.yaml`
- Modify: `data/i18n/en.yaml`, `data/i18n/ar.yaml`, `data/evidence/design-inferences.yaml`, `data/mechanics.yaml` (only if a genuinely new mechanic is needed)

Follow Cluster procedure A-G with these skills (domains in brackets; `[EF]` = `executive_function`, `[MEM]` = `memory`, `[ATT]` = `attention`).

| Skill id | Domains | Ages | Prerequisites |
|---|---|---|---|
| `ef.wm.hold-2` | EF, MEM | 3-4 | none |
| `ef.wm.hold-3` | EF, MEM | 4-5 | `ef.wm.hold-2` |
| `ef.wm.hold-4` | EF, MEM | 5-6 | `ef.wm.hold-3` |
| `ef.wm.sequence-order` | EF, MEM | 4-5 | `ef.wm.hold-3` |
| `ef.wm.manipulate-reverse` | EF, MEM | 5-7 | `ef.wm.sequence-order`, `ef.wm.hold-4` |
| `ef.wm.hold-5-plus` | EF, MEM | 6-8 | `ef.wm.hold-4` |
| `ef.ic.stop-go` | EF | 3-4 | none |
| `ef.ic.wait-for-signal` | EF | 3-4 | none |
| `ef.ic.go-no-go-selective` | EF | 4-5 | `ef.ic.stop-go` |
| `ef.ic.rule-conflict` | EF | 4-6 | `ef.ic.go-no-go-selective` |
| `ef.ic.delay-gratification` | EF | 4-6 | `ef.ic.wait-for-signal` |
| `ef.ic.suppress-dominant-response` | EF | 6-8 | `ef.ic.rule-conflict` |
| `ef.cf.sort-by-color` | EF | 3-4 | none |
| `ef.cf.sort-by-shape` | EF | 3-4 | none |
| `ef.cf.switch-sort-rule` | EF | 4-5 | `ef.cf.sort-by-color`, `ef.cf.sort-by-shape` |
| `ef.cf.multi-rule-switch` | EF | 5-7 | `ef.cf.switch-sort-rule` |
| `ef.cf.adapt-to-changed-rule` | EF | 6-8 | `ef.cf.multi-rule-switch` |
| `mem.recognition.familiar-items` | MEM | 2-4 | none |
| `mem.visual.pair-locations` | MEM | 3-5 | `mem.recognition.familiar-items` |
| `mem.episodic.retell-sequence-of-events` | MEM | 4-6 | `mem.recognition.familiar-items` |
| `mem.long-term.recall-after-delay` | MEM | 5-7 | `mem.episodic.retell-sequence-of-events` |
| `att.focus.track-moving-object` | ATT | 2-3 | none |
| `att.focus.visual-search-easy` | ATT | 2-4 | none |
| `att.focus.visual-search-crowded` | ATT | 4-6 | `att.focus.visual-search-easy` |
| `att.sustained.short-task` | ATT | 2-4 | none |
| `att.sustained.extended-task` | ATT | 4-6 | `att.sustained.short-task` |
| `att.selective.ignore-distractor` | ATT | 4-6 | `att.focus.visual-search-easy` |
| `att.shift.follow-cue-change` | ATT | 5-7 | `att.selective.ignore-distractor` |
| `att.divided.two-cues` | ATT | 6-8 | `att.selective.ignore-distractor` |

Attention skills are in the skill map only (attention is not a deep domain), so they need no games or rules.

**Suggested mechanic pairings** for step E (the mechanic ids already exist in `data/mechanics.yaml`): working memory uses `sequence-recall` and `position-recall`, with a transfer task on `physical-build` (an adult shows a short row of blocks, hides them, and the child rebuilds it); inhibitory control uses `go-no-go` and `wait-then-act`, with a transfer task on `physical-freeze`; cognitive flexibility uses `sort-by-rule` and `switch-sort-rule`, with a transfer task on `physical-sort`; memory uses `match-pairs` and `position-recall`, with `retell` as the transfer task for the episodic skills. The working-memory ladder should vary `working_memory_load` (anchors: hold 2, hold 3, hold 4, then reorder), keeping the other dimensions fixed at each step.

- [ ] **Step 1:** Author skills, evidence and i18n (Cluster procedure A, B, C).
- [ ] **Step 2:** Run `.venv/Scripts/python.exe -m nova_validate`. Expected: errors of rule `deep-coverage` only, one group per deep skill that still lacks games, rules or probes. Any other rule is a mistake to fix now.
- [ ] **Step 3:** Author transfer tasks, games and assessment rules (Cluster procedure D, E, F).
- [ ] **Step 4:** Run `.venv/Scripts/python.exe -m nova_validate --report`. Expected: `0 error(s)`.
- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add data
git commit -m "Add executive function, memory and attention skills, games and rules" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 14: Math and numeracy

**Files:**
- Modify: `data/skills/math/counting.yaml`, `data/games/math/counting.yaml`, `data/transfer_tasks/math-counting.yaml`, `data/assessment/math-counting.yaml`
- Create: `data/skills/math/{number,compare,operations,patterns,geometry,measurement,data}.yaml`, `data/games/math/{number,compare,operations,patterns,geometry,measurement,data}.yaml`, `data/transfer_tasks/math-*.yaml`, `data/assessment/math-*.yaml`
- Modify: `data/i18n/en.yaml`, `data/i18n/ar.yaml`, `data/evidence/design-inferences.yaml`

All skills are domain `math`, scope `universal`. Follow Cluster procedure A-G. `math.count.one-to-one-5` and `math.count.cardinality` already exist from Task 10; extend their games and tasks where the rest of the table needs them, and do not renumber them.

| Skill id | Ages | Prerequisites |
|---|---|---|
| `math.count.rote-to-10` | 3-5 | none |
| `math.count.one-to-one-10` | 4-5 | `math.count.one-to-one-5` |
| `math.count.rote-to-20` | 5-6 | `math.count.rote-to-10` |
| `math.count.on-from-number` | 5-7 | `math.count.cardinality`, `math.count.rote-to-20` |
| `math.count.by-2s-5s-10s` | 6-8 | `math.count.rote-to-20` |
| `math.number.subitize-3` | 2-4 | none |
| `math.number.recognize-1-5` | 3-4 | `math.number.subitize-3` |
| `math.number.recognize-1-10` | 4-5 | `math.number.recognize-1-5` |
| `math.number.quantity-to-numeral` | 4-5 | `math.count.cardinality`, `math.number.recognize-1-10` |
| `math.number.numeral-to-quantity` | 4-5 | `math.count.cardinality`, `math.number.recognize-1-10` |
| `math.number.recognize-11-20` | 5-6 | `math.number.recognize-1-10` |
| `math.number.place-value-tens-ones` | 6-8 | `math.number.recognize-11-20` |
| `math.compare.more-less-visual` | 3-4 | `math.number.subitize-3` |
| `math.compare.more-less-counting` | 4-5 | `math.compare.more-less-visual`, `math.count.cardinality` |
| `math.compare.more-less-numerals` | 5-6 | `math.compare.more-less-counting`, `math.number.recognize-1-10` |
| `math.compare.order-1-10` | 5-6 | `math.compare.more-less-numerals` |
| `math.compare.ordinal-positions` | 5-7 | `math.count.rote-to-10` |
| `math.operate.combine-concrete` | 4-5 | `math.count.cardinality` |
| `math.operate.take-away-concrete` | 4-6 | `math.count.cardinality` |
| `math.operate.add-within-5` | 5-6 | `math.operate.combine-concrete`, `math.number.recognize-1-5` |
| `math.operate.subtract-within-5` | 5-6 | `math.operate.take-away-concrete`, `math.number.recognize-1-5` |
| `math.operate.add-sub-within-10` | 6-7 | `math.operate.add-within-5`, `math.operate.subtract-within-5` |
| `math.operate.add-sub-within-20` | 6-8 | `math.operate.add-sub-within-10` |
| `math.pattern.repeat-ab` | 3-4 | none |
| `math.pattern.extend-abb-aab` | 4-6 | `math.pattern.repeat-ab` |
| `math.pattern.growing` | 6-8 | `math.pattern.extend-abb-aab` |
| `math.geometry.name-2d-shapes` | 3-5 | none |
| `math.geometry.compose-shapes` | 4-6 | `math.geometry.name-2d-shapes` |
| `math.geometry.3d-shapes` | 5-7 | `math.geometry.name-2d-shapes` |
| `math.measure.compare-length-size` | 3-5 | none |
| `math.measure.order-by-size` | 4-6 | `math.measure.compare-length-size` |
| `math.measure.non-standard-units` | 5-7 | `math.measure.order-by-size`, `math.count.one-to-one-10` |
| `math.data.sort-classify` | 3-5 | none |
| `math.data.simple-graph` | 6-8 | `math.data.sort-classify`, `math.count.one-to-one-10` |

**Suggested mechanic pairings:** counting uses `drag-to-count`, `tap-to-count` and `physical-counting`; number recognition and quantity-symbol links use `match-symbol-to-quantity` and `number-line-place`; comparison uses `compare-quantities` with `physical-sort` as the transfer task; operations use `drag-to-count` for combining and taking away, with `physical-build` as the transfer task; patterns use `pattern-continue` with `physical-build` (bead or block patterns); geometry uses `puzzle-assemble` with `physical-hunt` (find something round in your room, bring it to a grown-up) as the transfer task; measurement uses `compare-quantities` with `physical-hunt` (find something longer than your hand); data uses `sort-by-rule` with `physical-sort`. The transfer requirement is that the mechanic differs, not that the content differs.

**Transfer note for maths:** the evidence on early-maths interventions reports weak transfer to broader maths (see the Task 11 entries). Write the transfer probes so that they really change the representation (objects to numerals, screen to real objects), not only the pictures.

- [ ] **Step 1:** Author skills, evidence and i18n (Cluster procedure A, B, C).
- [ ] **Step 2:** Run the validator. Expected: `deep-coverage` errors only (deep skills without games, rules or probes yet).
- [ ] **Step 3:** Author transfer tasks, games and assessment rules (Cluster procedure D, E, F).
- [ ] **Step 4:** Run `.venv/Scripts/python.exe -m nova_validate --report`. Expected: `0 error(s)`.
- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add data
git commit -m "Add math and numeracy skills, games and rules" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 15: Universal oral-language skills

**Files:**
- Create: `data/skills/language/oral.yaml`
- Modify: `data/i18n/en.yaml`, `data/i18n/ar.yaml`, `data/evidence/design-inferences.yaml`

These are domain `language_literacy`, scope `universal`, and are in the skill map only (not deep, because they are not language-specific). Follow Cluster procedure A, B, C and G.

| Skill id | Ages | Prerequisites |
|---|---|---|
| `lang.oral.follow-1-step-instruction` | 2-3 | none |
| `lang.oral.follow-2-step-instruction` | 3-4 | `lang.oral.follow-1-step-instruction` |
| `lang.oral.follow-3-step-instruction` | 4-6 | `lang.oral.follow-2-step-instruction` |
| `lang.oral.answer-simple-questions` | 2-4 | none |
| `lang.oral.ask-questions` | 3-5 | `lang.oral.answer-simple-questions` |
| `lang.oral.turn-taking-conversation` | 2-4 | none |
| `lang.oral.describe-picture` | 3-5 | `lang.oral.answer-simple-questions` |
| `lang.oral.tell-simple-story` | 4-6 | `lang.oral.describe-picture` |
| `lang.oral.explain-reasoning` | 5-8 | `lang.oral.tell-simple-story` |

- [ ] **Step 1:** Author the nine skills, evidence and i18n.
- [ ] **Step 2:** Run `.venv/Scripts/python.exe -m nova_validate --report`. Expected: `0 error(s)`.
- [ ] **Step 3: Commit**

```bash
cd /d/hamada/nova
git add data
git commit -m "Add universal oral-language skills" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 16: Arabic literacy track

**Files:**
- Create: `data/skills/ar-literacy/*.yaml`, `data/games/ar-literacy/*.yaml`, `data/transfer_tasks/ar-literacy.yaml`, `data/assessment/ar-literacy.yaml`
- Modify: `data/langpacks/langpacks.yaml` (Arabic `slots_filled`), `data/i18n/en.yaml`, `data/i18n/ar.yaml`, `data/evidence/design-inferences.yaml`

All skills: domain `language_literacy`, `scope: language-specific`, `language: ar`, and the `slot` shown. The progression is Arabic's own, not a translation of the English track: listening, vocabulary, phonological awareness, letter recognition, letter shapes and positional forms, harakat, sound mapping, syllables, word building, early reading. Follow Cluster procedure A-G. Set the Arabic pack's `slots_filled` to the slots the skills actually fill (the validator checks it matches).

| Skill id | Slot | Ages | Prerequisites |
|---|---|---|---|
| `lit.ar.listen.follow-short-story` | listening | 3-5 | none |
| `lit.ar.vocab.everyday-nouns` | vocabulary | 2-4 | none |
| `lit.ar.vocab.action-and-descriptive-words` | vocabulary | 3-5 | `lit.ar.vocab.everyday-nouns` |
| `lit.ar.pa.syllable-clap` | phonological_awareness | 3-4 | none |
| `lit.ar.pa.rhyme-recognize` | phonological_awareness | 3-5 | `lit.ar.pa.syllable-clap` |
| `lit.ar.pa.initial-sound-isolate` | phonological_awareness | 4-6 | `lit.ar.pa.rhyme-recognize` |
| `lit.ar.pa.blend-syllables` | phonological_awareness | 4-5 | `lit.ar.pa.syllable-clap` |
| `lit.ar.pa.blend-phonemes` | phonological_awareness | 5-6 | `lit.ar.pa.blend-syllables`, `lit.ar.pa.initial-sound-isolate` |
| `lit.ar.pa.short-vs-long-vowel` | phonological_awareness | 4-6 | `lit.ar.pa.initial-sound-isolate` |
| `lit.ar.print.right-to-left-direction` | print_concepts | 3-4 | none |
| `lit.ar.print.word-boundaries-and-page-handling` | print_concepts | 3-5 | `lit.ar.print.right-to-left-direction` |
| `lit.ar.letter.recognize-isolated` | letter_knowledge | 4-5 | none |
| `lit.ar.letter.name-to-shape` | letter_knowledge | 4-6 | `lit.ar.letter.recognize-isolated` |
| `lit.ar.letter.discriminate-dots-and-shape` | letter_knowledge | 5-6 | `lit.ar.letter.recognize-isolated` |
| `lit.ar.letter.positional-forms` | letter_knowledge | 5-6 | `lit.ar.letter.recognize-isolated` |
| `lit.ar.letter.trace-isolated` | letter_knowledge | 4-6 | `lit.ar.letter.recognize-isolated` |
| `lit.ar.map.letter-to-sound` | sound_mapping | 4-6 | `lit.ar.letter.recognize-isolated`, `lit.ar.pa.initial-sound-isolate` |
| `lit.ar.map.short-vowel-harakat` | sound_mapping | 5-6 | `lit.ar.map.letter-to-sound`, `lit.ar.pa.short-vs-long-vowel` |
| `lit.ar.map.long-vowel-letters` | sound_mapping | 5-7 | `lit.ar.map.short-vowel-harakat` |
| `lit.ar.map.sukun-shadda` | sound_mapping | 6-8 | `lit.ar.map.short-vowel-harakat` |
| `lit.ar.map.tanween` | sound_mapping | 6-8 | `lit.ar.map.short-vowel-harakat` |
| `lit.ar.word.build-syllable` | word_building | 5-6 | `lit.ar.map.short-vowel-harakat`, `lit.ar.pa.blend-syllables` |
| `lit.ar.word.connect-letters` | word_building | 5-7 | `lit.ar.letter.positional-forms`, `lit.ar.word.build-syllable` |
| `lit.ar.word.build-3-letter-word` | word_building | 5-7 | `lit.ar.word.build-syllable`, `lit.ar.letter.positional-forms` |
| `lit.ar.read.vowelled-word-decode` | early_reading | 5-7 | `lit.ar.word.build-syllable`, `lit.ar.pa.blend-phonemes` |
| `lit.ar.read.high-frequency-words` | early_reading | 5-7 | `lit.ar.letter.recognize-isolated` |
| `lit.ar.read.short-vowelled-sentence` | early_reading | 6-8 | `lit.ar.read.vowelled-word-decode` |

**Suggested mechanic pairings:** phonological awareness uses `sound-match`, `rhyme-select`, `blend-sounds` and `segment-sounds`, with `oral-sound-game` (an adult-led spoken game, no screen) as the transfer task; letter knowledge uses `letter-match`, `catch-target` and `letter-trace`, with `print-hunt` (find the letter on a sign or in a book) as the transfer task; print concepts use `story-choice` with `print-hunt`; early reading uses `blend-sounds` with `print-hunt`. Set `language_dependencies: [ar]` on every Arabic game.

**Arabic-specific care:** the letter-forms and harakat skills depend on correct shaping and diacritic placement; the `mechanic` text must state which letters or forms a rung uses, and the difficulty anchors must name them (for example "isolated forms of 6 letters", "initial and final forms"). Record the instruction voice question (Modern Standard Arabic versus a dialect) as open in the Arabic language pack; do not decide it here.

- [ ] **Step 1:** Author skills, evidence and i18n (Cluster procedure A, B, C), and set the Arabic pack's `slots_filled`.
- [ ] **Step 2:** Run the validator. Expected: `deep-coverage` errors only.
- [ ] **Step 3:** Author transfer tasks, games and assessment rules (Cluster procedure D, E, F).
- [ ] **Step 4:** Run `.venv/Scripts/python.exe -m nova_validate --report`. Expected: `0 error(s)`.
- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add data
git commit -m "Add Arabic literacy track: skills, games, rules" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 17: English literacy track

**Files:**
- Create: `data/skills/en-literacy/*.yaml`, `data/games/en-literacy/*.yaml`, `data/transfer_tasks/en-literacy.yaml`, `data/assessment/en-literacy.yaml`
- Modify: `data/langpacks/langpacks.yaml` (English `slots_filled`), `data/i18n/en.yaml`, `data/i18n/ar.yaml`, `data/evidence/design-inferences.yaml`

All skills: domain `language_literacy`, `scope: language-specific`, `language: en`, and the `slot` shown. The progression is English's own: listening, vocabulary, rhyming, phonological awareness, letter recognition, letter-sound mapping, blending, word recognition, early reading. Follow Cluster procedure A-G. The Arabic i18n strings for English-track skills still describe the skill in Arabic (the skill is taught in English; parents may read the app in Arabic).

| Skill id | Slot | Ages | Prerequisites |
|---|---|---|---|
| `lit.en.listen.follow-short-story` | listening | 3-5 | none |
| `lit.en.vocab.everyday-nouns` | vocabulary | 2-4 | none |
| `lit.en.vocab.action-and-descriptive-words` | vocabulary | 3-5 | `lit.en.vocab.everyday-nouns` |
| `lit.en.pa.rhyme-recognize` | phonological_awareness | 3-5 | none |
| `lit.en.pa.rhyme-produce` | phonological_awareness | 4-5 | `lit.en.pa.rhyme-recognize` |
| `lit.en.pa.syllable-segment` | phonological_awareness | 3-5 | none |
| `lit.en.pa.initial-sound-isolate` | phonological_awareness | 4-6 | `lit.en.pa.rhyme-recognize` |
| `lit.en.pa.blend-onset-rime` | phonological_awareness | 4-6 | `lit.en.pa.syllable-segment` |
| `lit.en.pa.blend-phonemes` | phonological_awareness | 5-6 | `lit.en.pa.blend-onset-rime`, `lit.en.pa.initial-sound-isolate` |
| `lit.en.pa.segment-phonemes` | phonological_awareness | 5-7 | `lit.en.pa.blend-phonemes` |
| `lit.en.print.left-to-right-direction` | print_concepts | 3-4 | none |
| `lit.en.print.word-boundaries` | print_concepts | 4-6 | `lit.en.print.left-to-right-direction` |
| `lit.en.letter.recognize-uppercase` | letter_knowledge | 3-5 | none |
| `lit.en.letter.recognize-lowercase` | letter_knowledge | 4-6 | `lit.en.letter.recognize-uppercase` |
| `lit.en.letter.match-upper-lower` | letter_knowledge | 4-6 | `lit.en.letter.recognize-lowercase` |
| `lit.en.letter.name-to-shape` | letter_knowledge | 4-6 | `lit.en.letter.recognize-uppercase` |
| `lit.en.letter.trace-and-write` | letter_knowledge | 4-6 | `lit.en.letter.recognize-uppercase` |
| `lit.en.map.consonant-sounds` | sound_mapping | 4-6 | `lit.en.letter.recognize-uppercase`, `lit.en.pa.initial-sound-isolate` |
| `lit.en.map.short-vowel-sounds` | sound_mapping | 5-6 | `lit.en.map.consonant-sounds` |
| `lit.en.map.digraphs` | sound_mapping | 6-8 | `lit.en.map.consonant-sounds` |
| `lit.en.word.build-cvc` | word_building | 5-6 | `lit.en.map.short-vowel-sounds`, `lit.en.pa.blend-phonemes` |
| `lit.en.read.decode-cvc` | early_reading | 5-6 | `lit.en.word.build-cvc` |
| `lit.en.read.high-frequency-words` | early_reading | 5-7 | `lit.en.letter.recognize-lowercase` |
| `lit.en.read.short-sentence` | early_reading | 6-7 | `lit.en.read.decode-cvc` |

**Suggested mechanic pairings:** the same mechanic ids as the Arabic track are available (`sound-match`, `rhyme-select`, `blend-sounds`, `segment-sounds`, `letter-match`, `catch-target`, `letter-trace`, `print-hunt`, `oral-sound-game`); each skill still needs two distinct mechanics and a valid `cross_game` probe, chosen independently of the Arabic track. Set `language_dependencies: [en]` on every English game.

- [ ] **Step 1:** Author skills, evidence and i18n (Cluster procedure A, B, C), and set the English pack's `slots_filled`.
- [ ] **Step 2:** Run the validator. Expected: `deep-coverage` errors only.
- [ ] **Step 3:** Author transfer tasks, games and assessment rules (Cluster procedure D, E, F).
- [ ] **Step 4:** Run `.venv/Scripts/python.exe -m nova_validate --report`. Expected: `0 error(s)`.
- [ ] **Step 5: Commit**

```bash
cd /d/hamada/nova
git add data
git commit -m "Add English literacy track: skills, games, rules" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 18: Remaining domains (skill map only)

**Files:**
- Create: `data/skills/cognitive/*.yaml`, `data/skills/problem_solving/*.yaml`, `data/skills/visual_spatial/*.yaml`, `data/skills/fine_motor/*.yaml`, `data/skills/social_emotional/*.yaml`, `data/skills/creativity/*.yaml`, `data/skills/science_exploration/*.yaml`
- Modify: `data/i18n/en.yaml`, `data/i18n/ar.yaml`, `data/evidence/design-inferences.yaml`

These domains need skills only (no games or rules in this pass). Author at least 10 skills per domain, spread across ages 2-8, universal scope, each with observable indicators, real prerequisite edges where an ordering exists, and evidence (verified where Task 11 found it, otherwise a design inference). Sub-areas to cover:

| Domain | Id prefix | Sub-areas to cover |
|---|---|---|
| `cognitive` | `cog.` | categorising, cause and effect, sequencing events, matching and sorting, object permanence (early), analogies (late), simple deduction |
| `problem_solving` | `ps.` | trial and error, choosing a tool, planning steps, means-end reasoning, puzzles, trying a second strategy |
| `visual_spatial` | `vs.` | shape matching, spatial words (in, on, under, behind), mental rotation, following a simple map, block designs, symmetry |
| `fine_motor` | `fm.` | tapping and dragging accuracy, grasp, tracing lines and curves, drawing shapes, scissors, letter-forming precursors |
| `social_emotional` | `soc.` | naming emotions, calming strategies, empathy, sharing and turn-taking, cooperation, resolving a disagreement, self-awareness |
| `creativity` | `cre.` | pretend play, free drawing, rhythm and music, storytelling, trying a new idea, combining materials |
| `science_exploration` | `sci.` | observing, predicting, living and non-living, weather and seasons, simple experiments, measuring |

A skill in these domains is deep only if the validator says so; `problem_solving`, `fine_motor` and the others are not deep domains, so none should be. If the validator does flag a skill as a deep candidate, its domain tags are wrong.

- [ ] **Step 1:** Author at least 70 skills in total (10 per domain) with evidence and i18n.
- [ ] **Step 2:** Run `.venv/Scripts/python.exe -m nova_validate --report`. Expected: `0 error(s)`; `--report` shows skills in all twelve domains.
- [ ] **Step 3: Commit**

```bash
cd /d/hamada/nova
git add data
git commit -m "Add skill map for cognitive, problem solving, spatial, motor, social-emotional, creativity, science" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Phase 5: Language packs and the remaining chapters

### Task 19: Language pack completion and chapter 05

**Files:**
- Modify: `data/langpacks/langpacks.yaml`
- Create: `docs/curriculum/05-language-packs.md`

**Interfaces:**
- Consumes: the Arabic and English skills from Tasks 16 and 17.

- [ ] **Step 1: Mark Arabic and English complete only if the validator agrees**

In `data/langpacks/langpacks.yaml` set `status: complete` for `ar` and `en` once each fills all eight slots. Run `.venv/Scripts/python.exe -m nova_validate`. If it reports a pack "marked complete but does not fill slots", the fix is to add the missing skills in Task 16 or 17, not to weaken the status.

- [ ] **Step 2: Write chapter 05**

Sections, in order:
1. *The pack contract.* What a language pack must supply: script properties (direction, joining, diacritics, tonal), the eight shared slots and the skills that fill them, fonts and text shaping, voice and audio, an input method for tracing, and content sourcing rules. Include a checklist a new language must pass, which mirrors the validator's `langpack` rules.
2. *Shared versus language-specific.* Which skills are universal (math, executive function, memory, spatial, social-emotional, oral language) and need only translated strings, and which are language-specific.
3. *The Arabic track.* Its progression and why it differs from English: isolated and positional letter forms, dots as discriminators, harakat, long vowels (madd), tanween, sukun and shadda, syllable-first word building. Cite the Task 11 evidence, and say plainly where there is little Arabic-specific evidence.
4. *The English track.* Its progression, opaque orthography, letter names versus sounds, onset-rime and phoneme blending, CVC words first.
5. *Open question: Arabic instruction voice.* Modern Standard Arabic versus a dialect (for example Egyptian) for spoken instructions and prompts; literacy content is Modern Standard Arabic either way. State the trade-offs (comprehension of instructions versus exposure to the written standard) and that the decision is deferred to the language-pack sub-project.
6. *Extension notes: Chinese and Hindi.* State clearly that these are notes for a future pack, not validated designs. Chinese: characters and radicals instead of an alphabet (so `letter_knowledge` maps to character and stroke knowledge), pinyin and tones as the sound layer (tone is part of phonological awareness), stroke order, compounds for word building. Hindi: Devanagari akshara, matras, conjunct consonants, the inherent vowel, syllable-based reading. For each: what the shared slots would map to, what new skills are needed, and what the app must support (fonts, input, stroke animation). Both packs stay `contract_only` with no skills.

- [ ] **Step 3: Check citations and commit**

Re-run the citation check from Task 12 Step 3; expected `unknown evidence ids: []`.

```bash
cd /d/hamada/nova
git add data docs
git commit -m "Complete language packs and add chapter 05" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 20: Chapters 03 and 04

**Files:**
- Create: `docs/curriculum/03-skill-model.md`, `docs/curriculum/04-assessment-adaptivity.md`

- [ ] **Step 1: Write chapter 03, the skill model**

Sections: the skill node and every field (with the counting skills from `data/skills/math/counting.yaml` as the running example); mastery states and what each means; the seven difficulty dimensions with the anchor convention (`anchors[dimension][value]`), illustrated with `data/games/math/counting.yaml`; the evidence model as it applies to skills and games (basis, precedence, prerequisite edges labelled design inference when uncited); the game spec; how ids and files are organised.

- [ ] **Step 2: Write chapter 04, assessment and adaptivity**

Sections: the four assessment dimensions (performance, independence, transfer, confidence); transfer probes (cross_game, cross_context, delayed) with the reskin exclusion and one correct and one incorrect example each, taken from real records; the signal taxonomy (learning versus engagement) and why engagement never feeds mastery; the mastery rule structure (`data/assessment/math-counting.yaml` as the worked example); the full table of parameters, generated by reading `data/parameters/*.yaml` (id, value, unit, status), with a prominent statement that **every value is provisional and none is scientifically validated**; what calibration requires (reference chapter 08); that the choice of adaptive model (rule-based, knowledge tracing, item response theory) is deferred to the adaptive-engine sub-project.

- [ ] **Step 3: Check citations and commit**

Re-run the citation check; expected `unknown evidence ids: []`.

```bash
cd /d/hamada/nova
git add docs
git commit -m "Add chapters 03 and 04: skill model and assessment" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

### Task 21: Chapters 06, 07 and 08

**Files:**
- Create: `docs/curriculum/06-parent-reporting.md`, `07-safety-privacy-a11y.md`, `08-validation-roadmap.md`

- [ ] **Step 1: Write chapter 06, parent reporting**

Sections: what the dashboard may claim (the "evidence-based" versus "informed by" rule); estimate labelling for anything derived from a provisional parameter; skill-level reporting only, with example text in English and Arabic ("Counting: developing. Comparing quantities: needs practice") and the derivation from mastery states; what it must never say (no diagnosis, no screening, no comparison to norms, no "delay" language, no age-based pass or fail); engagement metrics are never presented as learning; a short guide for parents on the offline activities.

- [ ] **Step 2: Write chapter 07, safety, privacy and accessibility**

Sections: child data minimisation (what is collected, why, retention); the legal regimes to check for the launch markets (for example COPPA, GDPR and its children's provisions, and regional equivalents), each linked to its primary text after you open it, with a clear note that legal review is required before launch; content rules (no ads, no manipulative retention mechanics, no open chat, age-appropriate content); accessibility (right-to-left layout for Arabic, audio for pre-readers, colour-blind-safe cues, motor demands of each interaction, captions, reduced motion); screen-time stance citing the Task 11 evidence.

- [ ] **Step 3: Write chapter 08, validation and roadmap**

Sections: **educator review** (a review by early-childhood educators, and by a native Arabic-speaking literacy specialist for every Arabic string and the Arabic track, is required before any child uses the product); **pilot calibration plan** (what a pilot must measure to move each parameter from provisional to pilot-calibrated: sample size and ages, sites, consent and ethics, adult-rated criterion measures, the delayed-probe retention check, and the analysis to set thresholds); what `validated` requires (a linked calibration study); the limits of what this spec claims; and the roadmap of the next sub-projects in order: game engine and content schema, adaptive and assessment engine, parent dashboard, Arabic and English content production, then Chinese and Hindi packs, with art and audio alongside.

- [ ] **Step 4: Check citations and commit**

Re-run the citation check; expected `unknown evidence ids: []`.

```bash
cd /d/hamada/nova
git add docs
git commit -m "Add chapters 06 to 08: reporting, safety and roadmap" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
```

---

## Phase 6: Final verification

### Task 22: Definition-of-done check and handoff

**Files:**
- Modify: `docs/curriculum/08-validation-roadmap.md` (record the final counts)

- [ ] **Step 1: Run the full validator and tests**

Run from `tools/validate`:

```bash
.venv/Scripts/python.exe -m pytest -q
.venv/Scripts/python.exe -m nova_validate --report
```

Expected: `116 passed`, then `0 error(s)`. Record the report's counts (skills, deep-scope skills, games, transfer tasks, rules, parameters by status) in chapter 08.

- [ ] **Step 2: Check each spec "Definition of done" item against the evidence**

| Spec item | How to confirm |
|---|---|
| Validator passes | Step 1 output |
| Every skill and game cites evidence and declares the computed basis | Validator (`evidence-basis`, `evidence-ref`) |
| Every evidence entry has valid type and strength within the caps | Validator (`schema`, `evidence-cap`) |
| Every parameter provisional unless a study is linked | Validator (`parameter-status`); `--report` shows `provisional=N, pilot_calibrated=0, validated=0` |
| No assessment rule consumes an engagement signal | Validator (`engagement-signal`) |
| Every deep skill has a game, a rule, two mechanics and a valid cross_game probe | Validator (`deep-coverage`) |
| Language packs and i18n consistent | Validator (`langpack`, `i18n`) |
| Every evidence entry traces to a verified source | Run `grep -c "verified: false"` on `data/evidence`; every such entry must be a `design_inference` or `expert_consensus` type |
| Chapter citations resolve | The citation check from Task 12 Step 3 |
| Chapter 08 recommends educator review and states all parameters are provisional | Read the chapter |

- [ ] **Step 3: Engineer read-through**

Pick one skill, one game and one assessment rule at random from the finished data. Using only the YAML and `data/schema/`, answer without asking anyone: what does each field mean; how is the game's difficulty ladder read; which signals feed which mastery state; what would make this child's state move to Transfer. Any question that cannot be answered from the data and schemas is a gap; fix the chapter or schema that should have answered it and re-run the validator.

- [ ] **Step 4: Commit and tag**

```bash
cd /d/hamada/nova
git add -A
git commit -m "Record final validation counts in chapter 08" -m "Co-Authored-By: Claude Sonnet 5 <noreply@anthropic.com>"
git tag spec-v1
```

- [ ] **Step 5: Hand off**

Tell the user: the spec is complete and validated by the tools; all parameters are provisional; Arabic strings and the Arabic track need native-speaker educator review; the two open questions (Arabic instruction voice; target market for child-data law) remain open; and the next sub-project is the game engine and content schema.
