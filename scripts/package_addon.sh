#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

ROOT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
MANIFEST="$ROOT_DIR/package-manifest.txt"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR=$(mktemp -d)
trap 'rm -rf "$STAGE_DIR"' EXIT
ASSET_NAME=${ASSET_NAME:-@aviorstudio_gd-responsive.zip}

test -f "$MANIFEST"
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"

previous=""
count=0
while IFS= read -r relative || [ -n "$relative" ]; do
    [ -n "$relative" ] || { echo "blank package manifest entry" >&2; exit 1; }
    case "$relative" in
        /*|../*|*/../*|*/..|.|..)
            echo "unsafe package manifest entry: $relative" >&2
            exit 1
            ;;
    esac
    if [ -n "$previous" ] && [[ "$relative" < "$previous" ]]; then
        echo "package manifest must be sorted: $relative follows $previous" >&2
        exit 1
    fi
    previous=$relative
    source_path="$ROOT_DIR/addon/$relative"
    [ -f "$source_path" ] || { echo "missing declared package file: addon/$relative" >&2; exit 1; }
    [ ! -L "$source_path" ] || { echo "package symlink rejected: addon/$relative" >&2; exit 1; }
    mkdir -p "$STAGE_DIR/$(dirname "$relative")"
    cp "$source_path" "$STAGE_DIR/$relative"
    count=$((count + 1))
done < "$MANIFEST"

tracked=$(python3 - "$ROOT_DIR/addon" <<'PY'
import pathlib, sys
root = pathlib.Path(sys.argv[1])
for path in sorted(item for item in root.rglob("*") if item.is_file() or item.is_symlink()):
    print("addon/" + path.relative_to(root).as_posix())
PY
)
declared=$(while IFS= read -r path || [ -n "$path" ]; do printf 'addon/%s\n' "$path"; done < "$MANIFEST" | LC_ALL=C sort)
[ "$tracked" = "$declared" ] || {
    echo "tracked addon tree differs from closed package manifest" >&2
    diff -u <(printf '%s\n' "$declared") <(printf '%s\n' "$tracked") || true
    exit 1
}

(cd "$STAGE_DIR" && zip -q -X -r "$DIST_DIR/$ASSET_NAME" .)
sha256sum "$DIST_DIR/$ASSET_NAME" | tee "$DIST_DIR/$ASSET_NAME.sha256"
echo "PACKAGE_BUILT files=$count asset=$DIST_DIR/$ASSET_NAME"
