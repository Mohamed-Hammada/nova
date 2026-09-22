"""Id lifecycle rules: ids are permanent once shipped. An id may be marked
deprecated but never deleted from the data outright (design doc
2026-09-22, section 18.3). superseded_by, when set, must point at a live,
non-deprecated replacement id of the same kind, and requires
deprecated: true on the record that sets it."""
from __future__ import annotations

import json
from pathlib import Path

from .model import Issue, Record, Spec, error, index_by_id


def _default_baseline_path() -> Path:
    # The baseline is a ledger OF data/, so it lives alongside it, not in
    # tools/validate/. cli.py always passes an explicit path derived from
    # whatever --data root is in use; this default only matters for direct,
    # non-CLI callers.
    # tools/validate/nova_validate/id_lifecycle_rules.py -> <repo root>/data/id_baseline.json
    return Path(__file__).resolve().parents[3] / "data" / "id_baseline.json"


def _load_baseline(path: Path) -> dict[str, list[str]]:
    if not path.is_file():
        return {"skills": [], "games": []}
    return json.loads(path.read_text(encoding="utf-8"))


def write_baseline(spec: Spec, baseline_path: Path | None = None) -> None:
    path = baseline_path or _default_baseline_path()
    baseline = {
        "skills": sorted(skill["id"] for skill in spec.skills),
        "games": sorted(game["id"] for game in spec.games),
    }
    path.write_text(json.dumps(baseline, indent=2, sort_keys=True) + "\n", encoding="utf-8")


def check_id_lifecycle(spec: Spec, baseline_path: Path | None = None) -> list[Issue]:
    path = baseline_path or _default_baseline_path()
    issues: list[Issue] = []
    issues += _check_supersession(spec.skills, "skill")
    issues += _check_supersession(spec.games, "game")

    baseline = _load_baseline(path)
    current_skill_ids = {skill["id"] for skill in spec.skills}
    current_game_ids = {game["id"] for game in spec.games}
    for skill_id in baseline.get("skills", []):
        if skill_id not in current_skill_ids:
            issues.append(error(
                "id-lifecycle", f"skill:{skill_id}",
                "id was removed from the data; mark deprecated: true instead of deleting it",
            ))
    for game_id in baseline.get("games", []):
        if game_id not in current_game_ids:
            issues.append(error(
                "id-lifecycle", f"game:{game_id}",
                "id was removed from the data; mark deprecated: true instead of deleting it",
            ))
    return issues


def _check_supersession(records: list[Record], kind: str) -> list[Issue]:
    issues: list[Issue] = []
    by_id = index_by_id(records)
    for record in records:
        superseded_by = record.get("superseded_by")
        if superseded_by is None:
            continue
        where = f"{kind}:{record['id']}"
        if not record.get("deprecated", False):
            issues.append(error("id-lifecycle", where, "has superseded_by set but deprecated is not true"))
        target = by_id.get(superseded_by)
        if target is None:
            issues.append(error("id-lifecycle", where, f"superseded_by '{superseded_by}' does not exist"))
        elif target.get("deprecated", False):
            issues.append(error("id-lifecycle", where, f"superseded_by '{superseded_by}' is itself deprecated"))
    return issues
