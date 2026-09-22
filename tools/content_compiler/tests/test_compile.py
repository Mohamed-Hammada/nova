import json
import shutil
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from compile import build_bundle, main  # noqa: E402

REPO_ROOT = Path(__file__).resolve().parents[3]
DATA_ROOT = REPO_ROOT / "data"


def test_compiles_real_data_with_known_vertical_slice_ids():
    bundle = build_bundle(DATA_ROOT)
    assert bundle["schemaVersion"] == "1.0.0"
    assert bundle["contentVersion"]
    assert len(bundle["contentHash"]) == 64  # sha256 hex digest

    game_ids = {game["id"] for game in bundle["games"]}
    assert "game.math.bear-apples" in game_ids

    skill_ids = {skill["id"] for skill in bundle["skills"]}
    assert {"math.count.one-to-one-5", "math.count.cardinality"} <= skill_ids

    rule_ids = {rule["id"] for rule in bundle["assessment_rules"]}
    assert {"rule.math.count.one-to-one-5", "rule.math.count.cardinality"} <= rule_ids

    assert bundle["audio"]["en"]["game.math.bear-apples.name"]
    assert bundle["audio"]["ar"]["game.math.bear-apples.name"]


def test_bundle_hash_is_deterministic_across_two_compiles():
    first = build_bundle(DATA_ROOT)
    second = build_bundle(DATA_ROOT)
    assert first["contentHash"] == second["contentHash"]


def test_main_writes_output_file(tmp_path):
    out = tmp_path / "bundle.json"
    exit_code = main(["--data", str(DATA_ROOT), "--out", str(out)])
    assert exit_code == 0
    assert out.is_file()
    written = json.loads(out.read_text(encoding="utf-8"))
    assert written["contentHash"] == build_bundle(DATA_ROOT)["contentHash"]


def test_main_fails_and_writes_nothing_on_invalid_data(tmp_path):
    shutil.copytree(DATA_ROOT / "schema", tmp_path / "schema")
    (tmp_path / "skills").mkdir()
    (tmp_path / "skills" / "bad.yaml").write_text(
        "- id: broken.skill\n  domains: [math]\n", encoding="utf-8"
    )
    (tmp_path / "CONTENT_VERSION").write_text("0.0.1", encoding="utf-8")
    out = tmp_path / "out.json"
    exit_code = main(["--data", str(tmp_path), "--out", str(out)])
    assert exit_code == 1
    assert not out.is_file()
