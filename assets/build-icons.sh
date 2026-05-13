#!/usr/bin/env bash
# Regenerate favicon.ico and PNG icon sizes from assets/icon.png.
# Uses nearest-neighbor scaling to preserve crisp pixel boundaries.
# Run manually whenever icon.png changes; outputs are committed.

set -euo pipefail

cd "$(dirname "$0")/.."

SRC=assets/icon.png
ICO_OUT=static/favicon.ico
PNG_DIR=static/images

if [[ ! -f "$SRC" ]]; then
  echo "missing $SRC" >&2
  exit 1
fi

mkdir -p "$PNG_DIR"

magick "$SRC" -filter point -define icon:auto-resize=256,64,48,32,16 "$ICO_OUT"

for size in 32 64 128 180 256 512; do
  magick "$SRC" -filter point -resize "${size}x${size}" "$PNG_DIR/icon-${size}.png"
done

echo "wrote $ICO_OUT and $PNG_DIR/icon-{32,64,128,180,256,512}.png"
