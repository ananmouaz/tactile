#!/usr/bin/env bash
# Assemble the frames captured by example/lib/demo_capture.dart into an
# optimized GIF using a generated palette (smaller file, better color).
set -euo pipefail

FRAMES="${1:-/tmp/tactile_gif_frames}"
OUT="${2:-doc/tactile.gif}"
FPS=24
WIDTH=460
COLORS=128

mkdir -p "$(dirname "$OUT")"

ffmpeg -y -framerate "$FPS" -i "$FRAMES/frame_%04d.png" \
  -vf "fps=$FPS,scale=$WIDTH:-1:flags=lanczos,palettegen=max_colors=$COLORS:stats_mode=diff" \
  /tmp/tactile_palette.png

ffmpeg -y -framerate "$FPS" -i "$FRAMES/frame_%04d.png" -i /tmp/tactile_palette.png \
  -filter_complex "fps=$FPS,scale=$WIDTH:-1:flags=lanczos[x];[x][1:v]paletteuse=dither=bayer:bayer_scale=3" \
  "$OUT"

echo "wrote $OUT"
