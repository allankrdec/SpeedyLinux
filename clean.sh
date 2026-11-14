#!/bin/sh
# Remove chroot e binários da última build (mantém o cache de pacotes)
cd "$(dirname "$0")"

if [ -d build/config ]; then
  (cd build && sudo lb clean)
fi
