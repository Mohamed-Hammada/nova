#!/usr/bin/env bash
# Builds the web app, serves it locally, and runs the headless-Chrome smoke
# test (tools/web_smoke/web_smoke.mjs): play a full session, then check the
# progress survives a reload and a browser restart, with no request leaving
# the app's own origin. Needs Node.js 22+ and Google Chrome (or CHROME_PATH).
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/.."
command -v node >/dev/null || { echo "error: Node.js 22+ is required for the web smoke test" >&2; exit 1; }
./scripts/build_web.sh
port="${NOVA_SMOKE_PORT:-8787}"
python=""
for candidate in tools/validate/.venv/Scripts/python.exe tools/validate/.venv/bin/python python3 python; do
  if command -v "$candidate" >/dev/null 2>&1 || [ -x "$candidate" ]; then python="$candidate"; break; fi
done
"$python" -m http.server "$port" --bind 127.0.0.1 --directory app/build/web >/dev/null 2>&1 &
server=$!
trap 'kill $server 2>/dev/null || true' EXIT
sleep 1
node tools/web_smoke/web_smoke.mjs --port "$port"
