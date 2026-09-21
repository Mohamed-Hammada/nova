from nova_validate.coverage_rules import check_deep_coverage, check_probes
from tests.factory import get, make_spec, rules_of

GAME = "game.math.bear-snacks"
ONE_TO_ONE = "skill:math.count.one-to-one-5"
CARDINALITY = "skill:math.count.cardinality"


def where_of(issues):
    return {issue.where for issue in issues}


def probe(spec, probe_id):
    for candidate in get(spec.games, GAME)["transfer_probes"]:
        if candidate["id"] == probe_id:
            return candidate
    raise KeyError(probe_id)


def add_reskin_game(spec):
    reskin = dict(get(spec.games, "game.math.bear-snacks"))
    reskin["id"] = "game.math.penguin-fish"
    reskin["name_key"] = "game.math.penguin-fish.name"
    reskin["transfer_probes"] = []
    spec.games.append(reskin)
    return reskin


def test_valid_factory_spec_is_covered():
    spec = make_spec()
    assert check_probes(spec) == []
    assert check_deep_coverage(spec) == []


def test_deep_skill_without_a_game_is_reported():
    spec = make_spec()
    spec.games = [g for g in spec.games if g["id"] != "game.lit.ar.letter-catch"]
    issues = check_deep_coverage(spec)
    assert "skill:lit.ar.letter.recognize-isolated" in where_of(issues)
    assert any("no game" in issue.message for issue in issues)


def test_deep_skill_without_an_assessment_rule_is_reported():
    spec = make_spec()
    spec.assessment_rules = [r for r in spec.assessment_rules if r["skill"] != "math.count.cardinality"]
    issues = check_deep_coverage(spec)
    assert where_of(issues) == {CARDINALITY}
    assert "assessment rule" in issues[0].message


def test_single_mechanic_is_not_enough():
    spec = make_spec()
    spec.transfer_tasks = [t for t in spec.transfer_tasks if t["id"] != "task.math.count-objects-at-home"]
    issues = check_deep_coverage(spec)
    assert ONE_TO_ONE in where_of(issues)
    assert any("distinct mechanic" in issue.message for issue in issues)


def test_reskin_does_not_add_a_second_mechanic():
    spec = make_spec()
    add_reskin_game(spec)
    spec.transfer_tasks = [t for t in spec.transfer_tasks if t["id"] != "task.math.count-objects-at-home"]
    issues = check_deep_coverage(spec)
    assert any(i.where == ONE_TO_ONE and "distinct mechanic" in i.message for i in issues)


def test_cross_game_probe_pointing_at_a_reskin_is_invalid():
    spec = make_spec()
    reskin = add_reskin_game(spec)
    entry = probe(spec, "probe.one-to-one")
    entry["mechanic_id"] = reskin["mechanic_id"]
    entry["task_ref"] = reskin["id"]
    issues = check_probes(spec)
    assert rules_of(issues) == {"probe"}
    assert "reskin" in issues[0].message
    coverage = check_deep_coverage(spec)
    assert any(i.where == ONE_TO_ONE and "cross_game" in i.message for i in coverage)


def test_probe_mechanic_must_match_its_target():
    spec = make_spec()
    probe(spec, "probe.one-to-one")["mechanic_id"] = "print-hunt"
    issues = check_probes(spec)
    assert rules_of(issues) == {"probe"}
    assert "uses 'physical-counting'" in issues[0].message


def test_probe_task_ref_must_resolve():
    spec = make_spec()
    probe(spec, "probe.one-to-one")["task_ref"] = "task.nope"
    issues = check_probes(spec)
    assert rules_of(issues) == {"probe"}
    assert "task.nope" in issues[0].message


def test_probe_target_must_cover_the_probed_skill():
    spec = make_spec()
    entry = probe(spec, "probe.one-to-one")
    entry["mechanic_id"] = "print-hunt"
    entry["task_ref"] = "task.lit.ar.find-letter-in-print"
    issues = check_probes(spec)
    assert rules_of(issues) == {"probe"}
    assert "does not cover skill" in issues[0].message


def test_cross_context_probe_may_reuse_the_same_mechanic():
    spec = make_spec()
    entry = probe(spec, "probe.cardinality-later")
    entry["mechanic_id"] = "drag-to-count"
    entry["task_ref"] = GAME
    assert check_probes(spec) == []


def test_two_games_with_different_mechanics_satisfy_the_requirement():
    spec = make_spec()
    spec.transfer_tasks = [t for t in spec.transfer_tasks if t["id"] != "task.math.count-objects-at-home"]
    entry = probe(spec, "probe.cardinality")
    entry["mechanic_id"] = "match-symbol-to-quantity"
    entry["task_ref"] = "game.math.number-match"
    issues = check_deep_coverage(spec)
    assert CARDINALITY not in where_of(issues)


def test_deep_skill_needs_a_valid_cross_game_probe():
    spec = make_spec()
    get(spec.games, "game.lit.ar.letter-catch")["transfer_probes"] = []
    issues = check_deep_coverage(spec)
    assert where_of(issues) == {"skill:lit.ar.letter.recognize-isolated"}
    assert "cross_game" in issues[0].message


def test_cross_context_alone_does_not_satisfy_the_cross_game_requirement():
    spec = make_spec()
    get(spec.games, "game.lit.ar.letter-catch")["transfer_probes"][0]["type"] = "cross_context"
    issues = check_deep_coverage(spec)
    assert any("cross_game" in issue.message for issue in issues)


def test_non_deep_skills_need_no_coverage():
    spec = make_spec()
    assert not get(spec.skills, "soc.emotion.name-basic")["deep_scope"]
    assert "skill:soc.emotion.name-basic" not in where_of(check_deep_coverage(spec))
