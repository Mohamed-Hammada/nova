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
    "journeys": "journey.schema.json",
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
