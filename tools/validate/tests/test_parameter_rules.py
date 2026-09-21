from nova_validate.parameter_rules import check_parameters
from tests.factory import get, make_spec, rules_of


def test_valid_factory_parameters_pass():
    assert check_parameters(make_spec()) == []


def test_validated_without_a_study_is_rejected():
    spec = make_spec()
    get(spec.parameters, "param.test.advance")["status"] = "validated"
    assert rules_of(check_parameters(spec)) == {"parameter-status"}


def test_pilot_calibrated_without_a_study_is_rejected():
    spec = make_spec()
    get(spec.parameters, "param.test.advance")["status"] = "pilot_calibrated"
    assert rules_of(check_parameters(spec)) == {"parameter-status"}


def test_calibrated_with_a_study_is_accepted():
    spec = make_spec()
    parameter = get(spec.parameters, "param.test.advance")
    parameter["status"] = "pilot_calibrated"
    parameter["calibration_study"] = "study-2027-pilot-1"
    assert check_parameters(spec) == []


def test_borrowed_basis_requires_evidence():
    spec = make_spec()
    get(spec.parameters, "param.test.advance")["basis"] = "borrowed_from_literature"
    assert rules_of(check_parameters(spec)) == {"parameter-basis"}


def test_borrowed_basis_with_known_evidence_passes():
    spec = make_spec()
    parameter = get(spec.parameters, "param.test.advance")
    parameter["basis"] = "borrowed_from_literature"
    parameter["evidence_refs"] = ["ev.test.meta"]
    assert check_parameters(spec) == []


def test_unknown_evidence_ref_is_rejected():
    spec = make_spec()
    get(spec.parameters, "param.test.advance")["evidence_refs"] = ["ev.test.missing"]
    assert rules_of(check_parameters(spec)) == {"parameter-basis"}
