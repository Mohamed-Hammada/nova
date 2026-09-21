from nova_validate.assessment_rules import check_assessment_rules
from tests.factory import get, make_spec, rules_of

RULE = "rule.math.count.cardinality"


def test_valid_factory_rules_pass():
    assert check_assessment_rules(make_spec()) == []


def test_rule_for_unknown_skill_is_rejected():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["skill"] = "math.count.nope"
    assert rules_of(check_assessment_rules(spec)) == {"assessment-skill"}


def test_engagement_signal_cannot_feed_mastery():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["inputs"] = ["accuracy", "session_time"]
    issues = check_assessment_rules(spec)
    assert rules_of(issues) == {"engagement-signal"}
    assert "session_time" in issues[0].message


def test_completion_is_an_engagement_signal_too():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["inputs"] = ["completion"]
    assert rules_of(check_assessment_rules(spec)) == {"engagement-signal"}


def test_unknown_signal_is_rejected():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["inputs"] = ["mystery"]
    assert rules_of(check_assessment_rules(spec)) == {"assessment-signal"}


def test_unknown_parameter_is_rejected():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["state_criteria"]["secure"]["parameters"] = ["param.test.nope"]
    assert rules_of(check_assessment_rules(spec)) == {"assessment-parameter"}


def test_secure_cannot_rest_on_performance_alone():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["state_criteria"]["secure"]["requires_dimensions"] = ["performance"]
    issues = check_assessment_rules(spec)
    assert rules_of(issues) == {"assessment-dimension"}
    assert "secure" in issues[0].message


def test_transfer_requires_the_transfer_dimension():
    spec = make_spec()
    get(spec.assessment_rules, RULE)["state_criteria"]["transfer"]["requires_dimensions"] = ["performance", "independence"]
    issues = check_assessment_rules(spec)
    assert rules_of(issues) == {"assessment-dimension"}
    assert "transfer" in issues[0].message


def test_emerging_and_developing_require_performance():
    spec = make_spec()
    criteria = get(spec.assessment_rules, RULE)["state_criteria"]
    criteria["emerging"]["requires_dimensions"] = ["independence"]
    criteria["developing"]["requires_dimensions"] = ["independence"]
    assert len(check_assessment_rules(spec)) == 2
