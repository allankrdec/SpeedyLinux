#!/bin/sh

set -e

cd "$(dirname "$0")"

# live-build precisa de root
if [ "$(id -u)" -ne 0 ]; then
  exec sudo ARCH="${ARCH:-}" "$0" "$@"
fi

# ----------------------------------------------------------
# Versão (fonte única: ./os-release)
# ----------------------------------------------------------
if [ ! -f os-release ]; then
  echo "Arquivo os-release não encontrado na raiz do projeto"
  exit 1
fi

. ./os-release

: "${VERSION_ID:?VERSION_ID não definido no os-release}"
: "${PRETTY_NAME:?PRETTY_NAME não definido no os-release}"
: "${VERSION_CODENAME:?VERSION_CODENAME não definido no os-release}"

# ----------------------------------------------------------
# Arquitetura
# ----------------------------------------------------------
ARCH="${ARCH:-$(dpkg --print-architecture)}"

case "$ARCH" in
  amd64)
    # grub-pc = boot BIOS legado, grub-efi = boot UEFI
    BOOTLOADERS="grub-pc,grub-efi"
    ARCH_PACKAGES="grub-efi-amd64 amd64-microcode intel-microcode"
    ;;
  arm64)
    BOOTLOADERS="grub-efi"
    ARCH_PACKAGES="grub-efi-arm64"
    ;;
  *)
    echo "Arquitetura não suportada: $ARCH"
    exit 1
    ;;
esac

echo "===================================="
echo " $PRETTY_NAME build"
echo " Base:         Debian $VERSION_CODENAME"
echo " Arquitetura:  $ARCH"
echo "===================================="

# ----------------------------------------------------------
# Prepara o diretório build/ (preserva o cache de pacotes)
# ----------------------------------------------------------
mkdir -p build

# limpa a build anterior com lb clean (desmonta /proc, /sys etc. do chroot)
if [ -d build/config ]; then
  (cd build && lb clean)
fi

# cache de outra arquitetura não serve
if [ -f build/.arch ] && [ "$(cat build/.arch)" != "$ARCH" ]; then
  rm -rf build/cache
fi

find build -mindepth 1 -maxdepth 1 ! -name cache -exec rm -rf {} +
echo "$ARCH" > build/.arch

cp -r config build/

# os-release vai para a ISO (instalado pelo hook 01-speedy)
mkdir -p build/config/includes.chroot/etc/speedy
cp os-release build/config/includes.chroot/etc/speedy/os-release

# ----------------------------------------------------------
# Imagens (fonte única: ./images) -> destino dentro da ISO
# ----------------------------------------------------------
INCLUDES="build/config/includes.chroot"
BRANDING="usr/share/speedy/calamares/branding/speedy"

while read -r IMG DEST; do
  [ -n "$IMG" ] || continue
  if [ ! -f "images/$IMG" ]; then
    echo "Imagem não encontrada: images/$IMG"
    exit 1
  fi
  mkdir -p "$(dirname "$INCLUDES/$DEST")"
  cp "images/$IMG" "$INCLUDES/$DEST"
done <<EOF
logo.png        usr/share/speedy/logo.png
logo.png        $BRANDING/logo.png
welcome.png     $BRANDING/welcome.png
wallpaper.png   usr/share/speedy/wallpaper.png
installer.png   usr/share/icons/hicolor/256x256/apps/speedy-installer.png
avatar.png      etc/skel/.face
EOF

# pacotes específicos da arquitetura
printf '%s\n' $ARCH_PACKAGES > build/config/package-lists/arch.list.chroot

cd build

# --debian-installer live: não aparece no menu (o grub.cfg é customizado),
# mas gera o repositório local na ISO que o Calamares usa para instalar
# o grub-pc/grub-efi no sistema de destino sem precisar de internet.
lb config \
  --distribution "$VERSION_CODENAME" \
  --binary-images iso-hybrid \
  --debian-installer live \
  --bootloaders "$BOOTLOADERS" \
  --architectures "$ARCH" \
  --mirror-bootstrap http://deb.debian.org/debian \
  --mirror-chroot http://deb.debian.org/debian \
  --mirror-binary http://deb.debian.org/debian \
  --iso-preparer "Speedy" \
  --iso-volume "Speedy Linux $VERSION_ID" \
  --iso-publisher "Speedy Linux" \
  --archive-areas "main contrib non-free non-free-firmware"

lb build

cd ..

# ----------------------------------------------------------
# ISO final
# ----------------------------------------------------------
mkdir -p dist
ISO="dist/speedylinux-${VERSION_ID}-${ARCH}.iso"
mv "build/live-image-${ARCH}.hybrid.iso" "$ISO"

# devolve a ISO para o usuário que chamou o sudo
if [ -n "$SUDO_UID" ]; then
  chown "$SUDO_UID:$SUDO_GID" dist "$ISO"
fi

echo "===================================="
echo " Build finalizada: $ISO"
echo "===================================="
