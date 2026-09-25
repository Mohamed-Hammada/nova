#!/usr/bin/env bash
# Regenerates the content bundle, then runs the app in Chrome (pass
# `-d edge` or `-d web-server` to choose another target). Progress persists
# in the browser's own storage across reloads for this origin/port.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
./scripts/regenerate_content_bundle.sh
cd app
flutter pub get
if [[ " $* " == *" -d "* ]]; then device=(); else device=(-d chrome); fi
flutter run "${device[@]}" --no-web-resources-cdn --web-port 8686 "$@"
