#!/bin/sh

set -e

ARCH="${ARCH:-$(dpkg --print-architecture)}"

echo "===================================="
echo " Speedy Linux build"
echo " Arquitetura: $ARCH"
echo "===================================="

case "$ARCH" in
  amd64)
    BOOTLOADER="grub-efi grub-pc"
    ;;
  arm64)
    BOOTLOADER="grub-efi"
    ;;
  *)
    echo "Arquitetura não suportada: $ARCH"
    exit 1
    ;;
esac

rm -rf build
mkdir build

# copia sua config inteira, sem remover nada
cp -r config build/

# se existir grub customizado, ajusta a arquitetura automaticamente
GRUB_CFG="build/config/includes.binary/boot/grub/grub.cfg"

if [ -f "$GRUB_CFG" ]; then
  echo "Ajustando grub.cfg customizado para $ARCH..."

  # troca qualquer referência fixa de arquitetura no nome do kernel/initrd
  sed -i.bak \
    -e "s/-arm64/-${ARCH}/g" \
    -e "s/-amd64/-${ARCH}/g" \
    "$GRUB_CFG"

  # se você tiver referências EFI hardcoded em algum ponto
  if [ "$ARCH" = "amd64" ]; then
    sed -i.bak \
      -e "s/BOOTAA64.EFI/BOOTX64.EFI/g" \
      -e "s/grubaa64\\.efi/grubx64.efi/g" \
      "$GRUB_CFG"
  elif [ "$ARCH" = "arm64" ]; then
    sed -i.bak \
      -e "s/BOOTX64.EFI/BOOTAA64.EFI/g" \
      -e "s/grubx64\\.efi/grubaa64.efi/g" \
      "$GRUB_CFG"
  fi

  rm -f "${GRUB_CFG}.bak"
fi

cd build

lb config \
  --distribution trixie \
  --binary-images iso-hybrid \
  --debian-installer live \
  --bootloader "$BOOTLOADER" \
  --architectures "$ARCH" \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot http://deb.debian.org/debian \
  --mirror-binary http://deb.debian.org/debian \
  --iso-preparer "Speedy" \
  --iso-volume "Speedy Linux" \
  --iso-publisher "Speedy Linux" \
  --archive-areas "main contrib non-free non-free-firmware"

lb build

echo "===================================="
echo " Build finalizada para $ARCH"
echo "===================================="
