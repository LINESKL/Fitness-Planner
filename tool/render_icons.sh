#!/usr/bin/env bash
# SVG → PNG через headless Chrome (на Mac нет других растеризаторов SVG).
set -euo pipefail
cd "$(dirname "$0")/.."
CHROME="${CHROME:-/Applications/Google Chrome.app/Contents/MacOS/Google Chrome}"

render() { # <svg> <png> <ширина> <высота>
  "$CHROME" --headless=new --disable-gpu --hide-scrollbars --force-device-scale-factor=1 \
    --default-background-color=00000000 --window-size="$3,$4" \
    --screenshot="$PWD/$2" "file://$PWD/$1" >/dev/null 2>&1
}

render assets/icon/icon.svg assets/icon/icon.png 1024 1024
render assets/icon/foreground.svg assets/icon/foreground.png 1024 1024
render assets/icon/icon.svg store/icon-512.png 512 512
render store/feature-graphic.svg store/feature-graphic.png 1024 500
