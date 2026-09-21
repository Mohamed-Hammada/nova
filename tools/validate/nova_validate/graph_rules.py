"""Skill graph rules: references, cycles, age ranges, and deep-scope classification."""
from __future__ import annotations

from .model import (
    DEEP_AGE_WINDOW,
    DEEP_DOMAINS,
    DEEP_LANGUAGES,
    Issue,
    Record,
    Spec,
    error,
)


def find_cycle(edges: dict[str, list[str]]) -> list[str] | None:
    """Return one cycle as [a, b, ..., a], or None. Edges point from a skill to its prerequisites."""
    white, grey, black = 0, 1, 2
    color = {node: white for node in edges}
    for start in edges:
        if color[start] != white:
            continue
        color[start] = grey
        path = [start]
        stack = [(start, iter(edges[start]))]
        while stack:
            node, neighbours = stack[-1]
            for nxt in neighbours:
                if nxt not in color:
                    continue
                if color[nxt] == grey:
                    return path[path.index(nxt):] + [nxt]
                if color[nxt] == white:
                    color[nxt] = grey
                    path.append(nxt)
                    stack.append((nxt, iter(edges[nxt])))
                    break
            else:
                color[node] = black
                path.pop()
                stack.pop()
    return None


def is_deep_candidate(skill: Record) -> bool:
    """True if the skill belongs in the deep-coverage set (spec 3.1).

    The age window is exclusive at both ends: a skill qualifies when its range
    starts before age 6 and ends after age 3.
    """
    low, high = skill["age_range"]
    window_start, window_end = DEEP_AGE_WINDOW
    if not (low < window_end and high > window_start):
        return False
    if DEEP_DOMAINS & set(skill["domains"]):
        return True
    return (
        "language_literacy" in skill["domains"]
        and skill["scope"] == "language-specific"
        and skill.get("language") in DEEP_LANGUAGES
    )


def check_skill_graph(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    ids = {skill["id"] for skill in spec.skills}
    edges: dict[str, list[str]] = {}

    for skill in spec.skills:
        where = f"skill:{skill['id']}"
        low, high = skill["age_range"]
        if low > high:
            issues.append(error("age-range", where, f"age_range {[low, high]} starts after it ends"))

        targets: list[str] = []
        for edge in skill["prerequisites"]:
            target = edge["skill"]
            if target == skill["id"]:
                issues.append(error("prerequisite", where, "lists itself as a prerequisite"))
            elif target not in ids:
                issues.append(error("prerequisite", where, f"prerequisite '{target}' does not exist"))
            else:
                targets.append(target)
        edges[skill["id"]] = targets

        if is_deep_candidate(skill) and not skill["deep_scope"]:
            issues.append(error(
                "deep-scope", where,
                "falls in the deep-coverage set (EF, memory, math, Arabic/English literacy, ages 3-6) "
                "and must set deep_scope: true",
            ))

    cycle = find_cycle(edges)
    if cycle:
        issues.append(error("cycle", "skills", "prerequisite cycle: " + " -> ".join(cycle)))
    return issues
