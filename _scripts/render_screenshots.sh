#!/bin/bash
set -e

# Usage:
#   render_screenshots.sh              # render all languages
#   render_screenshots.sh zh-Hant      # render one language
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE="$(cd "$SCRIPT_DIR/.." && pwd)"

# Language → preview output folder mapping.
# zh-Hant and zh-Hans share the same rendered slide (same screenshots, same text).
LANG_LIST=("en" "zh-Hant" "ja" "es")
if [ -n "$1" ]; then
  LANG_LIST=("$1")
fi

out_dir_of() {
  case "$1" in
    en)      echo "EN" ;;
    zh-Hant) echo "ZH" ;;
    zh-Hans) echo "ZH" ;;
    ja)      echo "JP" ;;
    es)      echo "SP" ;;
    *)       echo "$1" ;;
  esac
}

cd "$BASE/_screenshot-gen"
python3 -m http.server 8787 >/dev/null 2>&1 &
SERVER_PID=$!
sleep 1
trap "kill $SERVER_PID 2>/dev/null" EXIT

# iPhone 6.5" App Store spec (App Store Connect accepts 1284×2778 / 1242×2688)
W=1284
H=2778
# Chrome headless --window-size includes ~87px of simulated browser chrome;
# compensate so the actual viewport matches H, then crop the PNG back to H.
CHROME_CHROME_PX=87
WIN_H=$((H + CHROME_CHROME_PX))

for LANG_ARG in "${LANG_LIST[@]}"; do
  OUT_SUB="$(out_dir_of "$LANG_ARG")"
  OUT="$BASE/docs/Preview/$OUT_SUB"
  mkdir -p "$OUT"
  for n in 1 2 3 4 5; do
    url="http://localhost:8787/slide.html?slide=$n&lang=$LANG_ARG"
    "$CHROME" \
      --headless=new \
      --disable-gpu \
      --hide-scrollbars \
      --no-sandbox \
      --force-device-scale-factor=1 \
      --window-size="${W},${WIN_H}" \
      --virtual-time-budget=4000 \
      --screenshot="$OUT/$n.png" \
      "$url" 2>/dev/null
    python3 - "$OUT/$n.png" "$W" "$H" <<'PY'
import sys
from PIL import Image
p, w, h = sys.argv[1], int(sys.argv[2]), int(sys.argv[3])
im = Image.open(p)
if im.size != (w, h):
    im.crop((0, 0, w, h)).save(p, "PNG", optimize=True)
PY
    echo "✓ $OUT/$n.png  (lang=$LANG_ARG)"
  done
done
