from nova_validate.graph_rules import check_skill_graph, find_cycle, is_deep_candidate
from tests.factory import get, make_spec, rules_of


def skill(ages, domains, scope="universal", language=None):
    record = {"age_range": ages, "domains": domains, "scope": scope}
    if language:
        record["language"] = language
    return record


def test_valid_factory_spec_has_a_clean_graph():
    assert check_skill_graph(make_spec()) == []


def test_missing_prerequisite_is_reported():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [{"skill": "math.count.nope"}]
    issues = check_skill_graph(spec)
    assert rules_of(issues) == {"prerequisite"}
    assert "math.count.nope" in issues[0].message


def test_self_prerequisite_is_reported():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [{"skill": "math.count.cardinality"}]
    assert rules_of(check_skill_graph(spec)) == {"prerequisite"}


def test_cycle_is_reported_with_its_path():
    spec = make_spec()
    get(spec.skills, "math.count.one-to-one-5")["prerequisites"] = [{"skill": "math.count.cardinality"}]
    issues = check_skill_graph(spec)
    assert rules_of(issues) == {"cycle"}
    assert "math.count.one-to-one-5" in issues[0].message and "math.count.cardinality" in issues[0].message


def test_find_cycle_unit():
    assert find_cycle({"a": ["b"], "b": ["c"], "c": []}) is None
    assert find_cycle({"a": ["b"], "b": ["a"]}) == ["a", "b", "a"]
    assert find_cycle({"a": ["b"], "b": ["c"], "c": ["b"]}) == ["b", "c", "b"]
    assert find_cycle({"a": ["b", "c"], "b": ["d"], "c": ["d"], "d": []}) is None


def test_reversed_age_range_is_reported():
    spec = make_spec()
    spec.skills[0]["age_range"] = [5, 3]
    assert rules_of(check_skill_graph(spec)) == {"age-range"}


def test_deep_candidate_must_be_marked_deep():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["deep_scope"] = False
    issues = check_skill_graph(spec)
    assert rules_of(issues) == {"deep-scope"}
    assert issues[0].where == "skill:math.count.cardinality"


def test_non_candidate_may_still_be_deep():
    spec = make_spec()
    get(spec.skills, "soc.emotion.name-basic")["deep_scope"] = True
    assert check_skill_graph(spec) == []


def test_deep_candidate_age_window_is_exclusive():
    assert is_deep_candidate(skill([3, 4], ["math"]))
    assert is_deep_candidate(skill([5, 6], ["math"]))
    assert is_deep_candidate(skill([2, 4], ["memory"]))
    assert not is_deep_candidate(skill([2, 3], ["math"]))
    assert not is_deep_candidate(skill([6, 8], ["math"]))


def test_deep_candidate_domains():
    assert is_deep_candidate(skill([4, 5], ["executive_function"]))
    assert not is_deep_candidate(skill([4, 5], ["attention"]))
    assert not is_deep_candidate(skill([4, 5], ["social_emotional"]))


def test_literacy_is_deep_only_for_arabic_and_english_specific_skills():
    assert is_deep_candidate(skill([4, 5], ["language_literacy"], "language-specific", "ar"))
    assert is_deep_candidate(skill([4, 5], ["language_literacy"], "language-specific", "en"))
    assert not is_deep_candidate(skill([4, 5], ["language_literacy"], "language-specific", "zh"))
    assert not is_deep_candidate(skill([4, 5], ["language_literacy"]))
