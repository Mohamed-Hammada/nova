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
