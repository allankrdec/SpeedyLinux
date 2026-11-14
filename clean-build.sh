#!/bin/sh
# Apaga tudo (inclusive o cache de pacotes) e gera a ISO do zero
set -e
cd "$(dirname "$0")"

if [ -d build/config ]; then
  (cd build && sudo lb clean --purge)
fi

sudo rm -rf build
./build.sh
