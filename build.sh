#!/bin/sh
#
# Gera a ISO do Speedy Linux. Precisa rodar em Linux (Debian).
# No macOS/Windows use ./docker-build.sh, que roda este script num container.
#
# Variáveis opcionais:
#   ARCH        amd64 | arm64 (padrão: a do host)
#   BUILD_DIR   diretório de trabalho do live-build (padrão: ./build)
#   DIST_DIR    onde a ISO final é gravada (padrão: ./dist)
#   HOST_OWNER  uid:gid dono da ISO final (padrão: quem chamou o sudo)
#   BACKPORTS   true | false: kernel e firmwares do <debian>-backports (padrão: true)

set -e

cd "$(dirname "$0")"
PROJECT_DIR="$(pwd)"

BUILD_DIR="${BUILD_DIR:-$PROJECT_DIR/build}"
DIST_DIR="${DIST_DIR:-$PROJECT_DIR/dist}"

# live-build precisa de root
if [ "$(id -u)" -ne 0 ]; then
  exec sudo ARCH="${ARCH:-}" BACKPORTS="${BACKPORTS:-}" BUILD_DIR="$BUILD_DIR" DIST_DIR="$DIST_DIR" \
    HOST_OWNER="${HOST_OWNER:-}" "$0" "$@"
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
BACKPORTS="${BACKPORTS:-true}"

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
echo " Backports:    $BACKPORTS"
echo " Build:        $BUILD_DIR"
echo "===================================="

# ----------------------------------------------------------
# Prepara o diretório de build (preserva o cache de pacotes)
# ----------------------------------------------------------
mkdir -p "$BUILD_DIR"

# limpa a build anterior com lb clean (desmonta /proc, /sys etc. do chroot)
if [ -d "$BUILD_DIR/config" ]; then
  (cd "$BUILD_DIR" && lb clean)
fi

# cache de outra arquitetura ou de outra versão do Debian não serve
TARGET="$VERSION_CODENAME-$ARCH"
if [ "$(cat "$BUILD_DIR/.target" 2>/dev/null)" != "$TARGET" ]; then
  rm -rf "$BUILD_DIR/cache"
fi

find "$BUILD_DIR" -mindepth 1 -maxdepth 1 ! -name cache -exec rm -rf {} +
echo "$TARGET" > "$BUILD_DIR/.target"

cp -r config "$BUILD_DIR/"

# os-release vai para a ISO (instalado pelo hook 01-speedy)
INCLUDES="$BUILD_DIR/config/includes.chroot"
mkdir -p "$INCLUDES/etc/speedy"
cp os-release "$INCLUDES/etc/speedy/os-release"

# ----------------------------------------------------------
# Imagens (fonte única: ./images) -> destino dentro da ISO
# ----------------------------------------------------------
BRANDING="usr/share/speedy/calamares/branding/speedy"

while read -r IMG DEST; do
  [ -n "$IMG" ] || continue
  if [ ! -f "images/$IMG" ]; then
    echo "Imagem não encontrada: images/$IMG"
    exit 1
  fi
  mkdir -p "$(dirname "$INCLUDES/$DEST")"
  install -m 644 "images/$IMG" "$INCLUDES/$DEST"
done <<EOF
logo.png        usr/share/speedy/logo.png
logo.png        $BRANDING/logo.png
welcome.png     $BRANDING/welcome.png
wallpaper.png   usr/share/speedy/wallpaper.png
installer.png   usr/share/icons/hicolor/256x256/apps/speedy-installer.png
avatar.png      etc/skel/.face
EOF

# pacotes específicos da arquitetura
printf '%s\n' $ARCH_PACKAGES > "$BUILD_DIR/config/package-lists/arch.list.chroot"

# ----------------------------------------------------------
# Kernel e firmwares do backports (placas Wi-Fi/rede mais novas)
# ----------------------------------------------------------
# Só o kernel e os firmwares vêm do backports; o resto continua no Debian
# estável. O pin vai para a ISO e para o sistema instalado (o Calamares já
# grava o <debian>-backports no sources.list), então o kernel e os
# firmwares continuam sendo atualizados pelo backports.
if [ "$BACKPORTS" = "true" ]; then
  mkdir -p "$BUILD_DIR/config/archives"
  cat > "$BUILD_DIR/config/archives/speedy-backports.pref" <<PREF
# Speedy Linux: kernel e firmwares do $VERSION_CODENAME-backports
Package: linux-image-* linux-headers-* linux-kbuild-* linux-base linux-base-* linux-binary-* linux-modules-* linux-support-*
Pin: release n=$VERSION_CODENAME-backports
Pin-Priority: 990

Package: firmware-*
Pin: release n=$VERSION_CODENAME-backports
Pin-Priority: 990
PREF
fi

cd "$BUILD_DIR"

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
  --backports "$BACKPORTS" \
  --iso-preparer "Speedy" \
  --iso-volume "Speedy Linux $VERSION_ID" \
  --iso-publisher "Speedy Linux" \
  --archive-areas "main contrib non-free non-free-firmware"

lb build

cd "$PROJECT_DIR"

# ----------------------------------------------------------
# ISO final
# ----------------------------------------------------------
mkdir -p "$DIST_DIR"
ISO="$DIST_DIR/speedylinux-${VERSION_ID}-${ARCH}.iso"
mv "$BUILD_DIR/live-image-${ARCH}.hybrid.iso" "$ISO"

# devolve a ISO para o usuário que chamou o sudo / o docker
OWNER="${HOST_OWNER:-${SUDO_UID:+$SUDO_UID:$SUDO_GID}}"
if [ -n "$OWNER" ]; then
  chown "$OWNER" "$DIST_DIR" "$ISO"
fi

echo "===================================="
echo " Build finalizada: $ISO"
echo "===================================="
