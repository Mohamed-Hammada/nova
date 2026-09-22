from nova_validate.audio_rules import check_audio
from nova_validate.keys import required_text_keys
from tests.factory import make_spec, rules_of


def test_valid_factory_spec_passes_audio_check():
    assert check_audio(make_spec()) == []


def test_missing_audio_asset_is_reported():
    spec = make_spec()
    del spec.audio["en"]["skill.math.count.one-to-one-5.name"]
    issues = check_audio(spec)
    assert rules_of(issues) == {"audio"}
    assert any("skill.math.count.one-to-one-5.name" in issue.message for issue in issues)


def test_missing_arabic_audio_asset_is_reported_separately_from_english():
    spec = make_spec()
    del spec.audio["ar"]["game.math.bear-snacks.name"]
    issues = check_audio(spec)
    assert any("'ar'" in issue.message and "game.math.bear-snacks.name" in issue.message for issue in issues)


def test_blank_audio_asset_path_is_rejected():
    spec = make_spec()
    spec.audio["en"]["skill.math.count.one-to-one-5.name"] = "   "
    issues = check_audio(spec)
    assert any("skill.math.count.one-to-one-5.name" in issue.message for issue in issues)


def test_games_and_tasks_never_require_a_description_key_audio_entry():
    # Only skills have a description_key (per skill.schema.json); games and
    # transfer tasks only need audio for name_key. required_text_keys is the
    # single shared source of which keys need coverage (used by both
    # audio_rules and i18n_rules), so this pins that it never invents a
    # description key for a game or task.
    spec = make_spec()
    game_and_task_wheres = {where for where, _ in required_text_keys(spec) if where.startswith(("game:", "transfer_task:"))}
    description_keys = {key for where, key in required_text_keys(spec) if where in game_and_task_wheres and key.endswith(".description")}
    assert description_keys == set()
