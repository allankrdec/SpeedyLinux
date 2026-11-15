#!/bin/sh
#
# Regera images/wallpaper.png e images/welcome.png a partir de
# tools/gerar-imagens.py. Roda num container Debian (só precisa do Docker).

set -e

cd "$(dirname "$0")/.."

docker run --rm -e DEBIAN_FRONTEND=noninteractive -v "$(pwd)":/src -w /src debian:trixie sh -c '
  set -e
  apt-get update -qq
  apt-get install -y -qq --no-install-recommends python3 librsvg2-bin fonts-noto-core >/dev/null
  python3 -I tools/gerar-imagens.py 3840 2160 --text > /tmp/wallpaper.svg
  python3 -I tools/gerar-imagens.py 2048 1280 --text > /tmp/welcome.svg
  rsvg-convert /tmp/wallpaper.svg -o images/wallpaper.png
  rsvg-convert /tmp/welcome.svg -o images/welcome.png
'

echo "Geradas: images/wallpaper.png (3840x2160), images/welcome.png (2048x1280)"
