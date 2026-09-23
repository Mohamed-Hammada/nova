#!/usr/bin/env bash
# Regenerates the content bundle, then runs the Flutter app's test suite.
# This is the real build step "produced fresh at build time" refers to --
# not an assumption a developer has to remember.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
./scripts/regenerate_content_bundle.sh
cd app
flutter test "$@"
