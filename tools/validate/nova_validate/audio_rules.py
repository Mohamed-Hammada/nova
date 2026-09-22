"""Audio-asset rules: every text key a skill, game, or transfer task uses
for its name (and a skill's description) has a non-empty spoken-audio asset
reference in every launch language, since the audience may not yet read
(design doc 2026-09-22, section 14.4). This checks that an asset reference
is declared, not that the referenced audio file exists on disk -- recording
real narration is a content-production task, out of scope here."""
from __future__ import annotations

from .keys import required_text_keys
from .model import Issue, Spec, error


def check_audio(spec: Spec) -> list[Issue]:
    needed = required_text_keys(spec)
    issues: list[Issue] = []
    for language, table in spec.audio.items():
        for where, key in needed:
            value = table.get(key)
            if not isinstance(value, str) or not value.strip():
                issues.append(error("audio", where, f"missing '{language}' audio asset for key '{key}'"))
    return issues
