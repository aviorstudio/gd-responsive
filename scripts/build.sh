#!/usr/bin/env bash
set -euo pipefail
bash scripts/package_addon.sh
bash scripts/verify_package.sh
