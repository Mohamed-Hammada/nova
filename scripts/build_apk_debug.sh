#!/usr/bin/env bash
# Regenerates the content bundle, then builds a debug APK. This is the
# reproducible packaging path: a fresh checkout has no committed
# content_bundle.json (it is a gitignored build artifact), so `flutter
# build` alone is not reproducible on its own -- this script is.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
./scripts/regenerate_content_bundle.sh
cd app
flutter build apk --debug
