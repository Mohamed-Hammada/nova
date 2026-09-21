from pathlib import Path

from nova_validate import model
from nova_validate.schema_rules import SCHEMA_FILES, check_schemas, check_unique_ids, load_schema
from tests.factory import get, make_spec, rules_of

SCHEMA_DIR = Path(__file__).resolve().parents[3] / "data" / "schema"


def messages(issues):
    return " | ".join(issue.message for issue in issues)


def test_valid_factory_spec_passes_schemas():
    assert check_schemas(make_spec(), SCHEMA_DIR) == []


def test_missing_required_field_is_reported():
    spec = make_spec()
    del spec.skills[0]["indicators"]
    issues = check_schemas(spec, SCHEMA_DIR)
    assert rules_of(issues) == {"schema"}
    assert "indicators" in messages(issues)


def test_unknown_property_is_rejected():
    spec = make_spec()
    spec.skills[0]["surprise"] = 1
    assert "surprise" in messages(check_schemas(spec, SCHEMA_DIR))


def test_unknown_domain_is_rejected():
    spec = make_spec()
    spec.skills[0]["domains"] = ["astrology"]
    assert check_schemas(spec, SCHEMA_DIR)


def test_language_specific_skill_requires_language():
    spec = make_spec()
    del get(spec.skills, "lit.ar.letter.recognize-isolated")["language"]
    assert "language" in messages(check_schemas(spec, SCHEMA_DIR))


def test_universal_skill_rejects_language_and_slot():
    spec = make_spec()
    spec.skills[0]["language"] = "ar"
    assert check_schemas(spec, SCHEMA_DIR)


def test_rung_must_define_every_difficulty_dimension():
    spec = make_spec()
    del spec.games[0]["difficulty"]["rungs"][0]["values"]["abstraction"]
    assert "abstraction" in messages(check_schemas(spec, SCHEMA_DIR))


def test_assessment_rule_needs_all_four_states():
    spec = make_spec()
    del spec.assessment_rules[0]["state_criteria"]["transfer"]
    assert "transfer" in messages(check_schemas(spec, SCHEMA_DIR))


def test_duplicate_ids_are_reported():
    spec = make_spec()
    spec.skills.append(dict(spec.skills[0]))
    issues = check_unique_ids(spec)
    assert rules_of(issues) == {"unique-id"}
    assert "math.count.one-to-one-5" in issues[0].where


def _enum(schema, *path):
    node = schema
    for part in path:
        node = node[part]
    return sorted(node)


def test_schema_enums_match_model_constants():
    load = lambda name: load_schema(SCHEMA_DIR, SCHEMA_FILES[name])
    skill, game, evidence = load("skills"), load("games"), load("evidence")
    rule, langpack = load("assessment_rules"), load("langpacks")

    assert _enum(skill, "properties", "domains", "items", "enum") == sorted(model.DOMAINS)
    assert _enum(skill, "properties", "slot", "enum") == sorted(model.SLOTS)
    assert _enum(langpack, "properties", "slots_filled", "items", "enum") == sorted(model.SLOTS)
    assert _enum(game, "properties", "difficulty", "properties", "varied", "items", "enum") == sorted(model.DIFFICULTY_DIMENSIONS)
    rung_values = game["properties"]["difficulty"]["properties"]["rungs"]["items"]["properties"]["values"]
    assert sorted(rung_values["required"]) == sorted(model.DIFFICULTY_DIMENSIONS)
    assert sorted(rung_values["properties"]) == sorted(model.DIFFICULTY_DIMENSIONS)
    assert _enum(evidence, "properties", "evidence_type", "enum") == sorted(model.EVIDENCE_TYPES)
    assert _enum(evidence, "properties", "evidence_strength", "enum") == sorted(model.EVIDENCE_STRENGTHS)
    assert _enum(rule, "$defs", "criterion", "properties", "requires_dimensions", "items", "enum") == sorted(model.ASSESSMENT_DIMENSIONS)
    assert sorted(rule["properties"]["state_criteria"]["required"]) == sorted(model.MASTERY_STATES)
