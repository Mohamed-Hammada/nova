"""Compile validated data/ YAML into one versioned, hashed content bundle for
the Flutter app to load at runtime. The app never parses YAML or runs JSON
Schema validation on-device (design doc 2026-09-22, section 17); this script
is the only place that does either, and it refuses to produce a bundle from
data the validator rejects."""
from __future__ import annotations

import argparse
import dataclasses
import hashlib
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "validate"))

from nova_validate.cli import run_all  # noqa: E402
from nova_validate.loader import load_spec  # noqa: E402

SCHEMA_VERSION = "1.0.0"


def default_data_root() -> Path:
    return Path(__file__).resolve().parents[2] / "data"


def default_out_path() -> Path:
    return Path(__file__).resolve().parents[2] / "app" / "assets" / "content" / "content_bundle.json"


def _read_content_version(data_root: Path) -> str:
    version_file = data_root / "CONTENT_VERSION"
    if not version_file.is_file():
        raise ValueError(f"{version_file} is required (a single version string, e.g. 0.1.0)")
    return version_file.read_text(encoding="utf-8").strip()


def build_bundle(data_root: Path) -> dict:
    spec = load_spec(data_root)
    issues = run_all(spec, data_root / "schema")
    errors = [issue for issue in issues if issue.level == "error"]
    if errors:
        raise ValueError("\n".join(str(issue) for issue in errors))

    content = dataclasses.asdict(spec)
    canonical = json.dumps(content, sort_keys=True, ensure_ascii=False)
    content_hash = hashlib.sha256(canonical.encode("utf-8")).hexdigest()

    return {
        "schemaVersion": SCHEMA_VERSION,
        "contentVersion": _read_content_version(data_root),
        "contentHash": content_hash,
        **content,
    }


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Compile data/ into a runtime content bundle.")
    parser.add_argument("--data", type=Path, default=default_data_root())
    parser.add_argument("--out", type=Path, default=default_out_path())
    args = parser.parse_args(argv)

    try:
        bundle = build_bundle(args.data)
    except ValueError as exc:
        print("Content compile failed:", file=sys.stderr)
        print(str(exc), file=sys.stderr)
        return 1

    args.out.parent.mkdir(parents=True, exist_ok=True)
    args.out.write_text(json.dumps(bundle, sort_keys=True, ensure_ascii=False, indent=2), encoding="utf-8")
    print(f"Wrote {args.out} (contentVersion={bundle['contentVersion']}, contentHash={bundle['contentHash'][:12]}...)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
