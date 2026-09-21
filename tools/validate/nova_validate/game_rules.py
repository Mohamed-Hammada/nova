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
