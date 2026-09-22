"""Command line entry point: python -m nova_validate [--data DIR] [--report] [--evidence-table]."""
from __future__ import annotations

import argparse
import sys
from pathlib import Path

from .assessment_rules import check_assessment_rules
from .audio_rules import check_audio
from .coverage_rules import check_deep_coverage, check_probes
from .evidence_rules import check_evidence_basis, check_evidence_entries
from .game_rules import check_games
from .graph_rules import check_skill_graph
from .i18n_rules import check_i18n
from .id_lifecycle_rules import check_id_lifecycle, write_baseline
from .langpack_rules import check_langpacks
from .loader import load_spec
from .model import Issue, Spec
from .parameter_rules import check_parameters
from .report import evidence_table, summary
from .schema_rules import check_schemas, check_unique_ids

# Rules that assume every record already has the right shape.
SEMANTIC_CHECKS = (
    check_skill_graph,
    check_evidence_entries,
    check_evidence_basis,
    check_parameters,
    check_assessment_rules,
    check_games,
    check_probes,
    check_deep_coverage,
    check_langpacks,
    check_i18n,
    check_audio,
)

# check_id_lifecycle is deliberately NOT in SEMANTIC_CHECKS / run_all: it
# needs a baseline file path derived from the actual --data root in use
# (data_root/id_baseline.json), which run_all's uniform check(spec) -> issues
# signature has no way to carry. main() calls it separately, once, with that
# path -- see below.


def run_all(spec: Spec, schema_dir: Path) -> list[Issue]:
    issues = check_schemas(spec, schema_dir) + check_unique_ids(spec)
    if any(issue.level == "error" for issue in issues):
        return issues  # semantic rules assume valid shapes, so stop here
    for check in SEMANTIC_CHECKS:
        issues.extend(check(spec))
    return issues


def default_data_root() -> Path:
    # tools/validate/nova_validate/cli.py -> repository root is three levels above the package
    return Path(__file__).resolve().parents[3] / "data"


def main(argv: list[str] | None = None) -> int:
    try:
        sys.stdout.reconfigure(encoding="utf-8")
    except (AttributeError, ValueError):
        pass  # not a real text stream (e.g. captured in a test)

    parser = argparse.ArgumentParser(prog="nova_validate", description="Validate the Nova curriculum data.")
    parser.add_argument("--data", type=Path, default=default_data_root(), help="data directory (default: <repo>/data)")
    parser.add_argument("--report", action="store_true", help="print counts after validating")
    parser.add_argument("--evidence-table", action="store_true", help="print the evidence table as Markdown and exit")
    parser.add_argument("--update-baseline", action="store_true", help="record the current id set as the baseline (only after a clean validation)")
    args = parser.parse_args(argv)

    spec = load_spec(args.data)
    if args.evidence_table:
        print(evidence_table(spec))
        return 0

    baseline_path = args.data / "id_baseline.json"
    issues = run_all(spec, args.data / "schema")
    if not any(issue.level == "error" for issue in issues):
        issues += check_id_lifecycle(spec, baseline_path)

    if args.update_baseline:
        error_count = sum(1 for issue in issues if issue.level == "error")
        if error_count:
            print(f"Refusing to update the baseline: {error_count} error(s) present.")
            return 1
        write_baseline(spec, baseline_path)
        print(f"Updated {baseline_path}")
        return 0
    for issue in issues:
        print(issue)
    error_count = sum(1 for issue in issues if issue.level == "error")
    if args.report and not any(issue.rule in ("schema", "unique-id") for issue in issues):
        print(summary(spec))
    print(f"{error_count} error(s), {len(issues) - error_count} warning(s)")
    return 1 if error_count else 0
