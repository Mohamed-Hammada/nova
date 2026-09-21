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
