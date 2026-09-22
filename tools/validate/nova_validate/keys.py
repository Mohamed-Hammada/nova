"""The (where, key) pairs every text-bearing i18n key belongs to. Shared by
i18n_rules (text) and audio_rules (spoken audio) so the two checks can never
drift apart on which keys need coverage."""
from __future__ import annotations

from .model import Spec


def required_text_keys(spec: Spec) -> list[tuple[str, str]]:
    needed: list[tuple[str, str]] = []
    for skill in spec.skills:
        needed.append((f"skill:{skill['id']}", skill["name_key"]))
        needed.append((f"skill:{skill['id']}", skill["description_key"]))
    for game in spec.games:
        needed.append((f"game:{game['id']}", game["name_key"]))
    for task in spec.transfer_tasks:
        needed.append((f"transfer_task:{task['id']}", task["name_key"]))
    return needed
