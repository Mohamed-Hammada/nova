#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STAGE3D_DIR="$SCRIPT_DIR/../app/stage3d"
ASSETS_DIR="$SCRIPT_DIR/../app/assets/stage3d"

echo "Building stage3d Vite bundle..."
cd "$STAGE3D_DIR"
npm run build

echo "Copying public models into assets/stage3d/models..."
mkdir -p "$ASSETS_DIR/models"
cp -r public/models/* "$ASSETS_DIR/models/"

echo "Stage3D build complete!"
