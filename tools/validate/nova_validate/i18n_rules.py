"""i18n rules: every key a record uses has a non-empty string in every launch language."""
from __future__ import annotations

from .model import Issue, Spec, error


def check_i18n(spec: Spec) -> list[Issue]:
    needed: list[tuple[str, str]] = []
    for skill in spec.skills:
        needed.append((f"skill:{skill['id']}", skill["name_key"]))
        needed.append((f"skill:{skill['id']}", skill["description_key"]))
    for game in spec.games:
        needed.append((f"game:{game['id']}", game["name_key"]))
    for task in spec.transfer_tasks:
        needed.append((f"transfer_task:{task['id']}", task["name_key"]))

    issues: list[Issue] = []
    for language, table in spec.i18n.items():
        for where, key in needed:
            value = table.get(key)
            if not isinstance(value, str) or not value.strip():
                issues.append(error("i18n", where, f"missing '{language}' string for key '{key}'"))
    return issues
