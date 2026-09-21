"""Language pack rules: skills belong to a real pack, and packs fill the shared slots."""
from __future__ import annotations

from collections import defaultdict

from .model import SLOTS, Issue, Record, Spec, error, index_by_id


def check_langpacks(spec: Spec) -> list[Issue]:
    issues: list[Issue] = []
    packs = index_by_id(spec.langpacks)
    skills_by_language: dict[str, list[Record]] = defaultdict(list)

    for skill in spec.skills:
        if skill["scope"] != "language-specific":
            continue
        language = skill["language"]
        if language not in packs:
            issues.append(error("langpack", f"skill:{skill['id']}", f"language '{language}' has no language pack"))
        else:
            skills_by_language[language].append(skill)

    for pack in spec.langpacks:
        where = f"langpack:{pack['id']}"
        pack_skills = skills_by_language.get(pack["id"], [])
        actual_slots = {skill["slot"] for skill in pack_skills if "slot" in skill}
        declared_slots = set(pack["slots_filled"])

        if pack["status"] == "contract_only" and pack_skills:
            issues.append(error("langpack", where, "is contract_only but has language-specific skills"))
        if declared_slots != actual_slots:
            issues.append(error(
                "langpack", where,
                f"slots_filled {sorted(declared_slots)} does not match the slots its skills fill {sorted(actual_slots)}",
            ))
        if pack["status"] == "complete":
            missing = sorted(set(SLOTS) - declared_slots)
            if missing:
                issues.append(error("langpack", where, f"is marked complete but does not fill slots {missing}"))
    return issues
