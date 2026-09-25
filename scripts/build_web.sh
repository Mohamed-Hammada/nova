#!/usr/bin/env bash
# Regenerates the content bundle, then builds the web app into app/build/web.
# Serve that folder with any static file server.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
./scripts/regenerate_content_bundle.sh
cd app
flutter build web --release
