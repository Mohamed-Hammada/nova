# Nova spec validator

Checks the curriculum data in `../../data` against the rules in
`docs/superpowers/specs/2026-09-21-nova-curriculum-design.md`.

```bash
python -m venv .venv
.venv/Scripts/python.exe -m pip install -r requirements.txt
.venv/Scripts/python.exe -m pytest -q                 # the validator's own tests
.venv/Scripts/python.exe -m nova_validate --report    # validate the data
.venv/Scripts/python.exe -m nova_validate --evidence-table   # Markdown table for chapter 01
```

Exit code is 1 when any error is found. Warnings do not fail the run.
