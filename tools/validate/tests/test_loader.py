import pytest

from nova_validate.loader import load_spec
from tests.factory import get, make_spec, write_spec


def write(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def test_loads_records_from_nested_directories(tmp_path):
    write(tmp_path / "skills" / "a.yaml", "- id: a.one\n- id: a.two\n")
    write(tmp_path / "skills" / "deep" / "b.yaml", "- id: b.one\n")
    spec = load_spec(tmp_path)
    assert sorted(skill["id"] for skill in spec.skills) == ["a.one", "a.two", "b.one"]


def test_loads_vocabulary_files_and_i18n(tmp_path):
    write(tmp_path / "mechanics.yaml", "- id: sort-by-rule\n  description: Sort items\n")
    write(tmp_path / "i18n" / "en.yaml", "skill.a.name: Counting\n")
    spec = load_spec(tmp_path)
    assert spec.mechanics[0]["id"] == "sort-by-rule"
    assert spec.i18n["en"]["skill.a.name"] == "Counting"
    assert spec.i18n["ar"] == {}


def test_missing_directories_yield_empty_collections(tmp_path):
    spec = load_spec(tmp_path)
    assert spec.skills == [] and spec.games == [] and spec.langpacks == []
    assert spec.mechanics == [] and spec.signals == []


def test_non_list_file_is_rejected(tmp_path):
    write(tmp_path / "skills" / "bad.yaml", "id: not-a-list\n")
    with pytest.raises(ValueError, match="top level"):
        load_spec(tmp_path)


def test_non_mapping_item_is_rejected(tmp_path):
    write(tmp_path / "skills" / "bad.yaml", "- just a string\n")
    with pytest.raises(ValueError, match="not a mapping"):
        load_spec(tmp_path)


def test_reads_utf8_arabic(tmp_path):
    write(tmp_path / "i18n" / "ar.yaml", "skill.a.name: العد\n")
    assert load_spec(tmp_path).i18n["ar"]["skill.a.name"] == "العد"


def test_factory_specs_are_independent():
    first, second = make_spec(), make_spec()
    first.skills[0]["indicators"].append("changed")
    assert second.skills[0]["indicators"] == ["Touches each object once while counting up to 5"]


def test_factory_spec_round_trips_through_disk(tmp_path):
    original = make_spec()
    write_spec(original, tmp_path)
    loaded = load_spec(tmp_path)
    assert loaded.skills == original.skills
    assert loaded.games == original.games
    assert get(loaded.langpacks, "ar")["script"]["direction"] == "rtl"
    assert loaded.i18n == original.i18n
