import json
from pathlib import Path

from nova_validate.research_rules import check_new_game_research
from tests.factory import errors_of, get, make_spec, rules_of


def _grandfather(tmp_path: Path, ids: list[str]) -> Path:
    path = tmp_path / "research_grandfathered.json"
    path.write_text(json.dumps({"games": ids}))
    return path


def test_grandfathered_games_are_exempt(tmp_path: Path) -> None:
    spec = make_spec()
    path = _grandfather(tmp_path, [g["id"] for g in spec.games])
    assert check_new_game_research(spec, path) == []


def test_a_new_game_citing_only_a_design_inference_is_an_error(tmp_path: Path) -> None:
    spec = make_spec()
    path = _grandfather(tmp_path, [])
    game = spec.games[0]
    game["evidence_refs"] = ["ev.test.design"]
    issues = check_new_game_research(spec, path)
    assert any(i.rule == "research-basis" and game["id"] in i.where for i in errors_of(issues))


def test_a_new_game_citing_unverified_research_is_an_error(tmp_path: Path) -> None:
    spec = make_spec()
    path = _grandfather(tmp_path, [])
    get(spec.evidence, "ev.test.framework")["verified"] = False
    game = spec.games[0]
    game["evidence_refs"] = ["ev.test.framework"]
    assert any(i.rule == "research-basis" and game["id"] in i.where for i in errors_of(check_new_game_research(spec, path)))


def test_non_japanese_research_passes_with_a_warning(tmp_path: Path) -> None:
    spec = make_spec()
    path = _grandfather(tmp_path, [])
    for game in spec.games:
        game["evidence_refs"] = ["ev.test.meta"]
    issues = check_new_game_research(spec, path)
    assert errors_of(issues) == []
    assert rules_of(issues) == {"research-japanese"}


def test_japanese_research_passes_clean(tmp_path: Path) -> None:
    spec = make_spec()
    path = _grandfather(tmp_path, [])
    get(spec.evidence, "ev.test.framework")["research_origin"] = ["JP"]
    for game in spec.games:
        game["evidence_refs"] = ["ev.test.framework"]
    assert check_new_game_research(spec, path) == []
