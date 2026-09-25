"""Journey rules: every level plays a real game made for that age group.

A journey is the level map for one age group. A level only chooses which game
is played (and, for counting games, which pictured objects); the Adaptive
Engine still chooses the rung inside it, so these rules check references and
age fit, never difficulty.
"""
from __future__ import annotations

from collections import Counter

from .model import JOURNEY_AGE_SPAN, MIN_JOURNEY_LEVELS, Issue, Spec, error, index_by_id


def _overlaps(a: list[float], b: list[float]) -> bool:
    return a[0] <= b[1] and a[1] >= b[0]


def check_journeys(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    games = index_by_id(spec.games)
    languages = {pack["id"] for pack in spec.langpacks if pack["status"] != "contract_only"}
    level_ids: Counter[str] = Counter()

    for journey in spec.journeys:
        where = f"journey:{journey['id']}"
        ages = journey["age_range"]
        if ages[0] > ages[1]:
            issues.append(error("age-range", where, f"age_range {ages} starts after it ends"))
        if len(journey["levels"]) < MIN_JOURNEY_LEVELS:
            issues.append(error(
                "journey-size", where,
                f"has {len(journey['levels'])} levels; every age group needs at least {MIN_JOURNEY_LEVELS}",
            ))

        for level in journey["levels"]:
            level_ids[level["id"]] += 1
            at = f"{where}/{level['id']}"
            if "game" in level:
                refs = [(None, level["game"])]
            else:
                refs = list(level["games_by_language"].items())
                missing = sorted(languages - set(level["games_by_language"]))
                if missing:
                    issues.append(error("journey-language", at, f"has no game for language(s) {missing}"))

            for language, game_id in refs:
                game = games.get(game_id)
                if game is None:
                    issues.append(error("journey-game", at, f"game '{game_id}' does not exist"))
                    continue
                if game.get("deprecated", False):
                    issues.append(error("journey-game", at, f"game '{game_id}' is deprecated"))
                if not _overlaps(game["age_range"], ages):
                    issues.append(error(
                        "journey-age", at,
                        f"game '{game_id}' is for ages {game['age_range']}, outside this journey's {ages}",
                    ))
                deps = set(game["language_dependencies"])
                if language is None and deps:
                    issues.append(error(
                        "journey-language", at,
                        f"game '{game_id}' depends on {sorted(deps)}; use games_by_language so every language gets a game",
                    ))
                if language is not None and deps and language not in deps:
                    issues.append(error(
                        "journey-language", at, f"game '{game_id}' is listed for '{language}' but depends on {sorted(deps)}",
                    ))

    for level_id, count in level_ids.items():
        if count > 1:
            issues.append(error("unique-id", f"level:{level_id}", f"level id is used {count} times"))

    if spec.journeys:
        low, high = JOURNEY_AGE_SPAN
        for age in range(low, high + 1):
            if not any(j["age_range"][0] <= age <= j["age_range"][1] for j in spec.journeys):
                issues.append(error("journey-coverage", "journeys", f"no journey covers age {age}"))
    return issues
