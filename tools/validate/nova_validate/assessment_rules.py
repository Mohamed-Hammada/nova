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
