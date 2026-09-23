#!/usr/bin/env bash
# Regenerates the content bundle, then builds the release web app into
# app/build/web. --no-web-resources-cdn serves CanvasKit from the app itself,
# so the built site fetches nothing from Google's CDN (or anywhere else):
# it is a static, self-contained, backend-free site.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
./scripts/regenerate_content_bundle.sh
for f in app/web/sqlite3.wasm app/web/drift_worker.js; do
  [ -f "$f" ] || { echo "error: $f is missing (run scripts/update_web_sqlite_assets.sh)" >&2; exit 1; }
done
cd app
flutter pub get
flutter build web --release --no-web-resources-cdn "$@"
echo "Built: app/build/web (serve it with any static file server)"
