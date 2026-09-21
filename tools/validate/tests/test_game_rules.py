from nova_validate.game_rules import check_games
from tests.factory import errors_of, get, make_spec, rules_of

GAME = "game.math.bear-snacks"


def test_valid_factory_games_pass():
    assert check_games(make_spec()) == []


def test_unknown_mechanic_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["mechanic_id"] = "teleport"
    assert rules_of(check_games(spec)) == {"mechanic"}


def test_unknown_skill_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["secondary_skills"] = ["math.count.nope"]
    assert rules_of(check_games(spec)) == {"game-skill"}


def test_unknown_signal_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["signals"] = ["accuracy", "mystery"]
    assert rules_of(check_games(spec)) == {"game-signal"}


def test_game_needs_at_least_one_learning_signal():
    spec = make_spec()
    get(spec.games, GAME)["signals"] = ["completion", "session_time"]
    issues = check_games(spec)
    assert rules_of(issues) == {"game-signal"}
    assert "learning" in issues[0].message


def test_unknown_progression_parameter_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["progression"]["advance_parameter"] = "param.test.nope"
    assert rules_of(check_games(spec)) == {"game-parameter"}


def test_language_dependency_needs_a_language_pack():
    spec = make_spec()
    get(spec.games, GAME)["language_dependencies"] = ["fr"]
    assert rules_of(check_games(spec)) == {"game-language"}


def test_varied_dimension_that_never_changes_is_rejected():
    spec = make_spec()
    for rung in get(spec.games, GAME)["difficulty"]["rungs"]:
        rung["values"]["item_complexity"] = 0
    issues = check_games(spec)
    assert rules_of(errors_of(issues)) == {"difficulty"}
    assert "item_complexity" in issues[0].message


def test_fixed_dimension_that_changes_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["difficulty"]["rungs"][1]["values"]["working_memory_load"] = 2
    issues = errors_of(check_games(spec))
    assert rules_of(issues) == {"difficulty"}
    assert "working_memory_load" in issues[0].message


def test_step_changing_two_dimensions_is_only_a_warning():
    spec = make_spec()
    rungs = get(spec.games, GAME)["difficulty"]["rungs"]
    rungs[1]["values"]["distractors"] = 1  # r2 now changes item_complexity and distractors
    issues = check_games(spec)
    assert errors_of(issues) == []
    assert rules_of(issues) == {"difficulty-step"}
    assert issues[0].level == "warning"


def test_duplicate_rung_ids_are_rejected():
    spec = make_spec()
    get(spec.games, GAME)["difficulty"]["rungs"][1]["id"] = "r1"
    assert "difficulty" in rules_of(check_games(spec))


def test_probe_must_target_a_skill_the_game_teaches():
    spec = make_spec()
    get(spec.games, GAME)["transfer_probes"][0]["skill"] = "soc.emotion.name-basic"
    assert rules_of(check_games(spec)) == {"probe"}


def test_probe_with_unknown_mechanic_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["transfer_probes"][0]["mechanic_id"] = "teleport"
    assert rules_of(check_games(spec)) == {"probe"}


def test_duplicate_probe_ids_are_rejected():
    spec = make_spec()
    probes = get(spec.games, GAME)["transfer_probes"]
    probes[1]["id"] = probes[0]["id"]
    assert rules_of(check_games(spec)) == {"probe"}


def test_transfer_task_with_unknown_mechanic_is_rejected():
    spec = make_spec()
    spec.transfer_tasks[0]["mechanic_id"] = "teleport"
    assert rules_of(check_games(spec)) == {"mechanic"}


def test_transfer_task_needs_a_learning_signal():
    spec = make_spec()
    spec.transfer_tasks[0]["signals"] = ["completion"]
    assert rules_of(check_games(spec)) == {"game-signal"}


def test_varied_dimension_without_anchors_is_rejected():
    spec = make_spec()
    del get(spec.games, GAME)["difficulty"]["anchors"]["distractors"]
    issues = check_games(spec)
    assert rules_of(issues) == {"difficulty-anchor"}
    assert "distractors" in issues[0].message


def test_value_beyond_the_named_anchors_is_rejected():
    spec = make_spec()
    get(spec.games, GAME)["difficulty"]["rungs"][2]["values"]["item_complexity"] = 2
    issues = errors_of(check_games(spec))
    assert rules_of(issues) == {"difficulty-anchor"}
    assert "value 2" in issues[0].message


def test_anchors_for_fixed_dimensions_are_optional():
    spec = make_spec()
    get(spec.games, GAME)["difficulty"]["anchors"]["independence"] = ["fully modelled"]
    assert check_games(spec) == []
