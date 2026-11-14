#!/bin/sh
# Instala as ferramentas de build no host Debian (também usado pelo Dockerfile)
set -e

ARCH=$(dpkg --print-architecture)

BASE_PACKAGES="live-build debootstrap xorriso squashfs-tools mtools dosfstools rsync wget curl gnupg ca-certificates"

if [ "$ARCH" = "amd64" ]; then
    EXTRA="grub-pc-bin grub-efi-amd64-bin"
elif [ "$ARCH" = "arm64" ]; then
    EXTRA="grub-efi-arm64-bin"
else
    echo "Arquitetura não suportada: $ARCH"
    exit 1
fi

SUDO=""
[ "$(id -u)" -eq 0 ] || SUDO="sudo"

$SUDO apt-get update
$SUDO env DEBIAN_FRONTEND=noninteractive apt-get install -y $BASE_PACKAGES $EXTRA
