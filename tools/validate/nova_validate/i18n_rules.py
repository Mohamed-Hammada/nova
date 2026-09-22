"""i18n rules: every key a record uses has a non-empty string in every launch language."""
from __future__ import annotations

from .keys import required_text_keys
from .model import Issue, Spec, error


def check_i18n(spec: Spec) -> list[Issue]:
    needed = required_text_keys(spec)
    issues: list[Issue] = []
    for language, table in spec.i18n.items():
        for where, key in needed:
            value = table.get(key)
            if not isinstance(value, str) or not value.strip():
                issues.append(error("i18n", where, f"missing '{language}' string for key '{key}'"))
    return issues
