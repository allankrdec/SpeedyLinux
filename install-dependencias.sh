#!/bin/sh
ARCH=$(dpkg --print-architecture)

BASE_PACKAGES="live-build debootstrap xorriso squashfs-tools grub-pc-bin mtools dosfstools isolinux syslinux-common syslinux-utils rsync wget curl gnupg ca-certificates"

if [ "$ARCH" = "amd64" ]; then
    EXTRA="grub-efi-amd64-bin"
elif [ "$ARCH" = "arm64" ]; then
    EXTRA="grub-efi-arm64-bin"
else
    echo "Arquitetura não suportada: $ARCH"
    exit 1
fi

sudo apt install -y $BASE_PACKAGES $EXTRA
