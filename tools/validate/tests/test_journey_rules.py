import copy

from nova_validate.journey_rules import check_journeys
from nova_validate.model import MIN_JOURNEY_LEVELS
from tests.factory import get, make_spec, rules_of


def _journey(journey_id="journey.test", ages=(2, 8), game="game.math.bear-snacks", count=MIN_JOURNEY_LEVELS):
    return {
        "id": journey_id,
        "name_key": f"{journey_id}.name",
        "age_range": list(ages),
        "levels": [{"id": f"{journey_id.split('.')[-1]}-{i:03d}", "game": game} for i in range(1, count + 1)],
    }


def _spec_with(*journeys):
    spec = make_spec()
    spec.journeys = [copy.deepcopy(j) for j in journeys]
    return spec


def test_a_full_journey_over_a_fitting_game_passes():
    assert check_journeys(_spec_with(_journey())) == []


def test_no_journeys_means_nothing_to_check():
    assert check_journeys(make_spec()) == []


def test_a_journey_needs_the_minimum_number_of_levels():
    issues = check_journeys(_spec_with(_journey(count=MIN_JOURNEY_LEVELS - 1)))
    assert rules_of(issues) == {"journey-size"}


def test_a_level_must_name_a_real_game():
    journey = _journey()
    journey["levels"][3]["game"] = "game.nope"
    issues = check_journeys(_spec_with(journey))
    assert rules_of(issues) == {"journey-game"}


def test_a_game_must_be_made_for_the_journey_ages():
    spec = _spec_with(_journey())
    get(spec.games, "game.math.bear-snacks")["age_range"] = [6, 8]
    spec.journeys[0]["age_range"] = [2, 3]
    issues = check_journeys(spec)
    assert "journey-age" in rules_of(issues)


def test_level_ids_are_unique_across_journeys():
    issues = check_journeys(_spec_with(_journey("journey.a"), _journey("journey.a")))
    assert "unique-id" in rules_of(issues)


def test_journeys_must_cover_every_age_from_2_to_8():
    issues = check_journeys(_spec_with(_journey(ages=(2, 5))))
    assert "journey-coverage" in rules_of(issues)
    assert any("age 6" in issue.message for issue in issues)


def test_a_language_game_must_go_through_games_by_language():
    spec = _spec_with(_journey())
    get(spec.games, "game.math.bear-snacks")["language_dependencies"] = ["ar"]
    issues = check_journeys(spec)
    assert "journey-language" in rules_of(issues)


def test_games_by_language_must_cover_every_active_language():
    spec = _spec_with(_journey())
    languages = sorted(p["id"] for p in spec.langpacks if p["status"] != "contract_only")
    spec.journeys[0]["levels"][0] = {"id": "test-001", "games_by_language": {languages[0]: "game.math.bear-snacks"}}
    issues = check_journeys(spec)
    if len(languages) > 1:
        assert "journey-language" in rules_of(issues)
    else:
        assert issues == []
