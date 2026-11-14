#!/bin/sh
#
# Gera a ISO do Speedy Linux dentro de um container Docker.
# Funciona em macOS, Linux e Windows (WSL), só precisa do Docker.
#
#   ./docker-build.sh            gera a ISO (arquitetura do Docker)
#   ARCH=amd64 ./docker-build.sh gera para outra arquitetura (emulada se
#                                for diferente da máquina: bem mais lento)
#   ./docker-build.sh clean      apaga o volume de build e o cache de pacotes
#
# A ISO é gravada em ./dist. O trabalho do live-build fica num volume do
# Docker (speedy-build-<debian>-<arch>), porque o chroot não funciona em pastas
# compartilhadas com o macOS. O volume guarda o cache entre builds.

set -e

cd "$(dirname "$0")"

if ! docker info >/dev/null 2>&1; then
  echo "Docker não está rodando."
  exit 1
fi

ARCH="${ARCH:-$(docker version --format '{{.Server.Arch}}')}"

case "$ARCH" in
  amd64|arm64) ;;
  aarch64) ARCH=arm64 ;;
  x86_64)  ARCH=amd64 ;;
  *)
    echo "Arquitetura não suportada: $ARCH"
    exit 1
    ;;
esac

# base Debian (fonte única: VERSION_CODENAME do ./os-release)
DEBIAN_CODENAME=$(. ./os-release && echo "$VERSION_CODENAME")
: "${DEBIAN_CODENAME:?VERSION_CODENAME não definido no os-release}"

IMAGE="speedylinux-builder:$DEBIAN_CODENAME-$ARCH"
VOLUME="speedy-build-$DEBIAN_CODENAME-$ARCH"

if [ "$1" = "clean" ]; then
  docker volume rm "$VOLUME" 2>/dev/null && echo "Volume $VOLUME removido." \
    || echo "Volume $VOLUME não existe."
  exit 0
fi

echo "Preparando imagem $IMAGE..."
docker build --platform "linux/$ARCH" \
  --build-arg DEBIAN_CODENAME="$DEBIAN_CODENAME" \
  -t "$IMAGE" .

mkdir -p dist

TTY=""
[ -t 1 ] && TTY="-t"

# --privileged: o live-build monta /proc, /sys e /dev dentro do chroot
docker run --rm -i $TTY --privileged \
  --platform "linux/$ARCH" \
  -v "$(pwd)":/src:ro \
  -v "$(pwd)/dist":/dist \
  -v "$VOLUME":/build \
  -e ARCH="$ARCH" \
  -e BUILD_DIR=/build \
  -e DIST_DIR=/dist \
  -e HOST_OWNER="$(id -u):$(id -g)" \
  "$IMAGE" \
  /src/build.sh
