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
