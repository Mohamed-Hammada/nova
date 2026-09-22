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
    audio = {
        "en": {key: f"assets/audio/en/{key}.mp3" for key in keys},
        "ar": {key: f"assets/audio/ar/{key}.mp3" for key in keys},
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
        audio=audio,
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
    for language, table in spec.audio.items():
        dump(root / "audio" / f"{language}.yaml", table)
