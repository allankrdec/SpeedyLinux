#!/bin/sh
ARCH=$(dpkg --print-architecture)

set -e

rm -rf build
mkdir build

# copia config ANTES
cp -r config build/

cd build

lb config \
  --distribution trixie \
  --binary-images iso-hybrid \
  --debian-installer live \
  --bootloader grub-efi \
  --architectures $ARCH \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot http://deb.debian.org/debian \
  --mirror-binary http://deb.debian.org/debian \
  --iso-preparer "Speedy" \
  --iso-volume "Speedy Linux" \
  --iso-publisher "Speedy Linux"\
  --archive-areas "main contrib non-free non-free-firmware"

lb build
