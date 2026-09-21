from nova_validate.evidence_rules import check_evidence_basis, check_evidence_entries, computed_basis
from nova_validate.model import index_by_id
from tests.factory import get, make_spec, rules_of


def test_valid_factory_spec_has_no_evidence_issues():
    spec = make_spec()
    assert check_evidence_entries(spec) == []
    assert check_evidence_basis(spec) == []


def test_design_inference_is_capped_at_emerging():
    spec = make_spec()
    get(spec.evidence, "ev.test.design")["evidence_strength"] = "moderate"
    assert rules_of(check_evidence_entries(spec)) == {"evidence-cap"}


def test_expert_consensus_is_capped_at_moderate():
    spec = make_spec()
    entry = get(spec.evidence, "ev.test.design")
    entry["evidence_type"] = "expert_consensus"
    entry["evidence_strength"] = "moderate"
    assert check_evidence_entries(spec) == []
    entry["evidence_strength"] = "strong"
    assert rules_of(check_evidence_entries(spec)) == {"evidence-cap"}


def test_empirical_evidence_must_be_verified():
    spec = make_spec()
    get(spec.evidence, "ev.test.meta")["verified"] = False
    assert rules_of(check_evidence_entries(spec)) == {"evidence-verified"}


def test_framework_evidence_must_be_verified():
    spec = make_spec()
    get(spec.evidence, "ev.test.framework")["verified"] = False
    assert rules_of(check_evidence_entries(spec)) == {"evidence-verified"}


def test_judgment_evidence_does_not_need_verification():
    spec = make_spec()
    assert get(spec.evidence, "ev.test.design")["verified"] is False
    assert check_evidence_entries(spec) == []


def test_computed_basis_precedence():
    index = index_by_id(make_spec().evidence)
    assert computed_basis(["ev.test.design"], index) == "judgment"
    assert computed_basis(["ev.test.framework"], index) == "framework"
    assert computed_basis(["ev.test.meta"], index) == "empirical"
    assert computed_basis(["ev.test.design", "ev.test.framework"], index) == "framework"
    assert computed_basis(["ev.test.framework", "ev.test.meta"], index) == "empirical"
    assert computed_basis(["ev.test.design", "ev.test.meta", "ev.test.framework"], index) == "empirical"


def test_skill_declaring_empirical_from_judgment_evidence_is_rejected():
    spec = make_spec()
    spec.skills[0]["evidence_basis"] = "empirical"
    issues = check_evidence_basis(spec)
    assert rules_of(issues) == {"evidence-basis"}
    assert "skill:math.count.one-to-one-5" in issues[0].where


def test_any_empirical_reference_forces_empirical_basis():
    spec = make_spec()
    skill = spec.skills[0]
    skill["evidence_refs"] = ["ev.test.design", "ev.test.meta"]
    skill["evidence_basis"] = "judgment"
    assert rules_of(check_evidence_basis(spec)) == {"evidence-basis"}
    skill["evidence_basis"] = "empirical"
    assert check_evidence_basis(spec) == []


def test_framework_plus_empirical_cannot_declare_framework():
    spec = make_spec()
    skill = spec.skills[0]
    skill["evidence_refs"] = ["ev.test.framework", "ev.test.meta"]
    skill["evidence_basis"] = "framework"
    assert rules_of(check_evidence_basis(spec)) == {"evidence-basis"}


def test_judgment_plus_framework_must_declare_framework():
    spec = make_spec()
    skill = spec.skills[0]
    skill["evidence_refs"] = ["ev.test.design", "ev.test.framework"]
    skill["evidence_basis"] = "judgment"
    assert rules_of(check_evidence_basis(spec)) == {"evidence-basis"}
    skill["evidence_basis"] = "framework"
    assert check_evidence_basis(spec) == []


def test_unknown_evidence_reference_is_reported_once():
    spec = make_spec()
    spec.skills[0]["evidence_refs"] = ["ev.test.missing"]
    issues = check_evidence_basis(spec)
    assert rules_of(issues) == {"evidence-ref"}
    assert len(issues) == 1


def test_game_basis_is_checked_too():
    spec = make_spec()
    spec.games[0]["evidence_basis"] = "empirical"
    issues = check_evidence_basis(spec)
    assert rules_of(issues) == {"evidence-basis"}
    assert issues[0].where == "game:game.math.bear-snacks"


def test_prerequisite_edge_evidence_must_resolve():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [
        {"skill": "math.count.one-to-one-5", "evidence_refs": ["ev.test.missing"]}
    ]
    assert rules_of(check_evidence_basis(spec)) == {"evidence-ref"}


def test_prerequisite_edge_with_valid_evidence_passes():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [
        {"skill": "math.count.one-to-one-5", "evidence_refs": ["ev.test.meta"]}
    ]
    assert check_evidence_basis(spec) == []
