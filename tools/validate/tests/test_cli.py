import shutil
from pathlib import Path

from nova_validate.cli import main, run_all
from nova_validate.report import evidence_table, summary
from tests.factory import errors_of, get, make_spec, rules_of, write_spec

SCHEMA_DIR = Path(__file__).resolve().parents[3] / "data" / "schema"


def write_data(tmp_path, spec):
    write_spec(spec, tmp_path)
    shutil.copytree(SCHEMA_DIR, tmp_path / "schema")
    return tmp_path


def test_valid_factory_spec_has_no_issues_at_all():
    assert run_all(make_spec(), SCHEMA_DIR) == []


def test_schema_errors_stop_semantic_rules():
    spec = make_spec()
    del spec.skills[0]["indicators"]
    spec.skills[1]["evidence_basis"] = "judgment"  # a semantic error that must not be reported yet
    assert rules_of(run_all(spec, SCHEMA_DIR)) == {"schema"}


def test_semantic_errors_from_every_family_are_collected():
    spec = make_spec()
    spec.skills[1]["evidence_basis"] = "judgment"
    del spec.i18n["en"]["skill.math.count.cardinality.name"]
    get(spec.assessment_rules, "rule.math.count.cardinality")["inputs"] = ["session_time"]
    found = rules_of(errors_of(run_all(spec, SCHEMA_DIR)))
    assert {"evidence-basis", "i18n", "engagement-signal"} <= found


def test_main_returns_zero_for_valid_data_on_disk(tmp_path, capsys):
    data = write_data(tmp_path, make_spec())
    assert main(["--data", str(data)]) == 0
    assert "0 error(s), 0 warning(s)" in capsys.readouterr().out


def test_main_returns_one_and_prints_errors(tmp_path, capsys):
    spec = make_spec()
    spec.skills[1]["evidence_basis"] = "judgment"
    data = write_data(tmp_path, spec)
    assert main(["--data", str(data)]) == 1
    out = capsys.readouterr().out
    assert "ERROR [evidence-basis]" in out
    assert "1 error(s)" in out


def test_warnings_do_not_fail_the_run(tmp_path, capsys):
    spec = make_spec()
    get(spec.games, "game.math.bear-snacks")["difficulty"]["rungs"][1]["values"]["distractors"] = 1
    data = write_data(tmp_path, spec)
    assert main(["--data", str(data)]) == 0
    assert "WARNING [difficulty-step]" in capsys.readouterr().out


def test_report_flag_prints_counts(tmp_path, capsys):
    data = write_data(tmp_path, make_spec())
    assert main(["--data", str(data), "--report"]) == 0
    out = capsys.readouterr().out
    assert "skills: 4 (deep_scope: 3)" in out
    assert "evidence_basis: empirical=1, framework=2, judgment=1" in out
    assert "prerequisite edges: 1 (cited: 0, design inference: 1)" in out
    assert "parameters: provisional=3, pilot_calibrated=0, validated=0" in out


def test_evidence_table_lists_every_entry():
    table = evidence_table(make_spec())
    assert table.splitlines()[0].startswith("| id | type | strength")
    assert "| ev.test.meta | meta_analysis | moderate | True |" in table
    assert len(table.splitlines()) == 2 + 3


def test_evidence_table_flag_prints_markdown(tmp_path, capsys):
    data = write_data(tmp_path, make_spec())
    assert main(["--data", str(data), "--evidence-table"]) == 0
    assert "| ev.test.design | design_inference | emerging |" in capsys.readouterr().out


def test_summary_counts_cited_edges():
    spec = make_spec()
    get(spec.skills, "math.count.cardinality")["prerequisites"] = [
        {"skill": "math.count.one-to-one-5", "evidence_refs": ["ev.test.meta"]}
    ]
    assert "cited: 1, design inference: 0" in summary(spec)
