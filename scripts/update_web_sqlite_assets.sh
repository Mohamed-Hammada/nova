#!/usr/bin/env bash
# Re-downloads app/web/sqlite3.wasm and app/web/drift_worker.js for the
# sqlite3 and drift versions currently resolved in app/pubspec.lock, and
# rewrites their pins (version + sha256) in app/web/sqlite_web_assets.json.
# Run after upgrading drift or sqlite3; test/web_platform_guard_test.dart
# fails until the pins match the lockfile again. Development-time only: the
# built app never downloads these.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../app"
version() { awk -v pkg="  $1:" '$0==pkg{f=1} f&&/version:/{gsub(/"/,"",$2); print $2; exit}' pubspec.lock; }
sqlite_version="$(version sqlite3)"
drift_version="$(version drift)"
curl -fsSL -o web/sqlite3.wasm "https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-${sqlite_version}/sqlite3.wasm"
curl -fsSL -o web/drift_worker.js "https://github.com/simolus3/drift/releases/download/drift-${drift_version}/drift_worker.js"
python - "$sqlite_version" "$drift_version" <<'PY'
import hashlib, json, sys
sqlite_version, drift_version = sys.argv[1], sys.argv[2]
path = "web/sqlite_web_assets.json"
manifest = json.load(open(path, encoding="utf-8"))
for name, package, version, url in [
    ("sqlite3.wasm", "sqlite3", sqlite_version, f"https://github.com/simolus3/sqlite3.dart/releases/download/sqlite3-{sqlite_version}/sqlite3.wasm"),
    ("drift_worker.js", "drift", drift_version, f"https://github.com/simolus3/drift/releases/download/drift-{drift_version}/drift_worker.js"),
]:
    digest = hashlib.sha256(open(f"web/{name}", "rb").read()).hexdigest()
    manifest[name] = {"package": package, "version": version, "source": url, "sha256": digest}
json.dump(manifest, open(path, "w", encoding="utf-8"), indent=2)
open(path, "a", encoding="utf-8").write("\n")
PY
echo "Updated to sqlite3 ${sqlite_version} / drift ${drift_version}."
