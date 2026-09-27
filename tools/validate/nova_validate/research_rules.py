"""Research rule (product owner, 2026-09-27): every new game is based on
published research.

A game that is not on the frozen grandfathered list (the games that existed
before the rule, data/research_grandfathered.json) must cite at least one
verified empirical or framework source -- a design inference or expert
opinion alone is not enough. Japanese research is preferred: when none of a
new game's evidence has "JP" in its `research_origin`, the validator warns.

The grandfathered list is never updated by tooling (unlike id_baseline.json),
so re-baselining can never let a new game skip this rule.
"""
from __future__ import annotations

import json
from pathlib import Path

from .model import EVIDENCE_TYPES, Issue, Spec, error, index_by_id, warning


def _default_path() -> Path:
    return Path(__file__).resolve().parents[3] / "data" / "research_grandfathered.json"


def load_grandfathered(path: Path | None = None) -> set[str]:
    path = path or _default_path()
    if not path.is_file():
        return set()
    return set(json.loads(path.read_text(encoding="utf-8")).get("games", []))


def check_new_game_research(spec: Spec, grandfathered_path: Path | None = None) -> list[Issue]:
    grandfathered = load_grandfathered(grandfathered_path)
    evidence = index_by_id(spec.evidence)
    issues: list[Issue] = []
    for game in spec.games:
        if game["id"] in grandfathered or game.get("deprecated"):
            continue
        where = f"game:{game['id']}"
        cited = [evidence[ref] for ref in game["evidence_refs"] if ref in evidence]
        research = [e for e in cited if EVIDENCE_TYPES[e["evidence_type"]] != "judgment" and e["verified"]]
        if not research:
            issues.append(error(
                "research-basis", where,
                "a new game must cite at least one verified research source (empirical or framework evidence); "
                "design inferences and expert opinion alone are not enough",
            ))
            continue
        if not any("JP" in e.get("research_origin", []) for e in research):
            issues.append(warning(
                "research-japanese", where,
                "none of this game's research is Japanese (research_origin: [JP]); Japanese research is preferred when it exists",
            ))
    return issues
