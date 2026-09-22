"""Load the YAML spec data from disk into a Spec."""
from __future__ import annotations

from pathlib import Path

import yaml

from .model import Record, Spec

# Spec attribute -> subdirectory of the data root (every *.yaml below it is a list of records).
RECORD_DIRS = {
    "skills": "skills",
    "games": "games",
    "transfer_tasks": "transfer_tasks",
    "evidence": "evidence",
    "parameters": "parameters",
    "assessment_rules": "assessment",
    "langpacks": "langpacks",
}

# Spec attribute -> single file at the data root (a list of records).
RECORD_FILES = {
    "mechanics": "mechanics.yaml",
    "signals": "signals.yaml",
}

I18N_LANGUAGES = ("en", "ar")
AUDIO_LANGUAGES = ("en", "ar")


def _read_yaml(path: Path):
    return yaml.safe_load(path.read_text(encoding="utf-8"))


def _load_list(path: Path) -> list[Record]:
    data = _read_yaml(path)
    if data is None:
        return []
    if not isinstance(data, list):
        raise ValueError(f"{path}: top level must be a YAML list of records")
    for index, item in enumerate(data):
        if not isinstance(item, dict):
            raise ValueError(f"{path}: item {index} is not a mapping")
    return data


def _load_dir(directory: Path) -> list[Record]:
    records: list[Record] = []
    if directory.is_dir():
        for path in sorted(directory.rglob("*.yaml")):
            records.extend(_load_list(path))
    return records


def _load_flat_table(directory: Path, languages: tuple[str, ...]) -> dict[str, dict[str, str]]:
    table: dict[str, dict[str, str]] = {}
    for language in languages:
        path = directory / f"{language}.yaml"
        data = _read_yaml(path) if path.is_file() else None
        if data is not None and not isinstance(data, dict):
            raise ValueError(f"{path}: must be a flat YAML mapping of key -> string")
        table[language] = data or {}
    return table


def _load_i18n(directory: Path) -> dict[str, dict[str, str]]:
    return _load_flat_table(directory, I18N_LANGUAGES)


def load_spec(data_root: Path) -> Spec:
    root = Path(data_root)
    fields: dict[str, list[Record]] = {
        attr: _load_dir(root / subdir) for attr, subdir in RECORD_DIRS.items()
    }
    for attr, filename in RECORD_FILES.items():
        path = root / filename
        fields[attr] = _load_list(path) if path.is_file() else []
    return Spec(
        i18n=_load_i18n(root / "i18n"),
        audio=_load_flat_table(root / "audio", AUDIO_LANGUAGES),
        **fields,
    )
