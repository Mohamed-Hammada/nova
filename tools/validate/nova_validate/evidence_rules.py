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
