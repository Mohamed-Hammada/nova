import json
from pathlib import Path

from nova_validate.id_lifecycle_rules import check_id_lifecycle, write_baseline
from tests.factory import get, make_spec, rules_of


def test_no_baseline_file_is_not_an_error(tmp_path: Path) -> None:
    spec = make_spec()
    missing = tmp_path / "id_baseline.json"
    assert check_id_lifecycle(spec, missing) == []


def test_removed_skill_id_is_an_error(tmp_path: Path) -> None:
    baseline = tmp_path / "id_baseline.json"
    baseline.write_text(json.dumps({"skills": ["math.count.one-to-one-5", "ghost.skill"], "games": []}))
    spec = make_spec()
    issues = check_id_lifecycle(spec, baseline)
    assert rules_of(issues) == {"id-lifecycle"}
    assert any("ghost.skill" in issue.where for issue in issues)


def test_removed_game_id_is_an_error(tmp_path: Path) -> None:
    baseline = tmp_path / "id_baseline.json"
    baseline.write_text(json.dumps({"skills": [], "games": ["game.math.bear-snacks", "ghost.game"]}))
    spec = make_spec()
    issues = check_id_lifecycle(spec, baseline)
    assert any("ghost.game" in issue.where for issue in issues)


def test_write_baseline_then_check_passes(tmp_path: Path) -> None:
    baseline = tmp_path / "id_baseline.json"
    spec = make_spec()
    write_baseline(spec, baseline)
    assert check_id_lifecycle(spec, baseline) == []


def test_superseded_by_requires_deprecated_true(tmp_path: Path) -> None:
    spec = make_spec()
    get(spec.skills, "math.count.one-to-one-5")["superseded_by"] = "math.count.cardinality"
    issues = check_id_lifecycle(spec, tmp_path / "missing.json")
    assert any("deprecated is not true" in issue.message for issue in issues)


def test_superseded_by_must_exist(tmp_path: Path) -> None:
    spec = make_spec()
    skill = get(spec.skills, "math.count.one-to-one-5")
    skill["deprecated"] = True
    skill["superseded_by"] = "no.such.skill"
    issues = check_id_lifecycle(spec, tmp_path / "missing.json")
    assert any("does not exist" in issue.message for issue in issues)


def test_superseded_by_target_cannot_itself_be_deprecated(tmp_path: Path) -> None:
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["deprecated"] = True
    skill = get(spec.skills, "math.count.one-to-one-5")
    skill["deprecated"] = True
    skill["superseded_by"] = "math.count.cardinality"
    issues = check_id_lifecycle(spec, tmp_path / "missing.json")
    assert any("is itself deprecated" in issue.message for issue in issues)


def test_valid_deprecation_passes(tmp_path: Path) -> None:
    spec = make_spec()
    skill = get(spec.skills, "math.count.one-to-one-5")
    skill["deprecated"] = True
    skill["superseded_by"] = "math.count.cardinality"
    assert check_id_lifecycle(spec, tmp_path / "missing.json") == []
