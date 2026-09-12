#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
ASSET_NAME=${ASSET_NAME:-@aviorstudio_gd-responsive.zip}
python3 "$ROOT_DIR/scripts/verify_package.py" "$ROOT_DIR/package-manifest.txt" "$ROOT_DIR/dist/$ASSET_NAME"
