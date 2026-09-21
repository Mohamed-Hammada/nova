from nova_validate.i18n_rules import check_i18n
from nova_validate.langpack_rules import check_langpacks
from nova_validate.model import SLOTS
from tests.factory import get, make_spec, rules_of


def test_valid_factory_langpacks_pass():
    assert check_langpacks(make_spec()) == []


def test_skill_in_an_unknown_language_is_rejected():
    spec = make_spec()
    get(spec.skills, "lit.ar.letter.recognize-isolated")["language"] = "fr"
    issues = check_langpacks(spec)
    assert "langpack" in rules_of(issues)
    assert any("fr" in issue.message for issue in issues)


def test_contract_only_pack_cannot_have_skills():
    spec = make_spec()
    get(spec.langpacks, "ar")["status"] = "contract_only"
    issues = check_langpacks(spec)
    assert any("contract_only" in issue.message for issue in issues)


def test_declared_slots_must_match_skill_slots():
    spec = make_spec()
    get(spec.langpacks, "ar")["slots_filled"] = []
    issues = check_langpacks(spec)
    assert rules_of(issues) == {"langpack"}
    assert "does not match" in issues[0].message


def test_complete_pack_must_fill_every_slot():
    spec = make_spec()
    get(spec.langpacks, "ar")["status"] = "complete"
    issues = check_langpacks(spec)
    assert any("complete" in issue.message for issue in issues)


def test_complete_pack_filling_every_slot_passes():
    spec = make_spec()
    pack = get(spec.langpacks, "ar")
    pack["status"] = "complete"
    pack["slots_filled"] = list(SLOTS)
    for index, slot in enumerate(s for s in SLOTS if s != "letter_knowledge"):
        clone = dict(get(spec.skills, "lit.ar.letter.recognize-isolated"))
        clone["id"] = f"lit.ar.extra-{index}"
        clone["slot"] = slot
        clone["deep_scope"] = True
        spec.skills.append(clone)
    assert check_langpacks(spec) == []


def test_valid_factory_i18n_passes():
    assert check_i18n(make_spec()) == []


def test_missing_english_string_is_reported():
    spec = make_spec()
    del spec.i18n["en"]["skill.math.count.cardinality.name"]
    issues = check_i18n(spec)
    assert rules_of(issues) == {"i18n"}
    assert issues[0].where == "skill:math.count.cardinality"
    assert "'en'" in issues[0].message


def test_missing_arabic_string_is_reported():
    spec = make_spec()
    del spec.i18n["ar"]["game.math.bear-snacks.name"]
    issues = check_i18n(spec)
    assert issues[0].where == "game:game.math.bear-snacks"
    assert "'ar'" in issues[0].message


def test_blank_string_counts_as_missing():
    spec = make_spec()
    spec.i18n["ar"]["task.math.count-objects-at-home.name"] = "   "
    assert rules_of(check_i18n(spec)) == {"i18n"}
