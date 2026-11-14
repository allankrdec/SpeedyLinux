# Ambiente de build do Speedy Linux (usado pelo docker-build.sh)
# DEBIAN_CODENAME vem do VERSION_CODENAME do ./os-release, para que o
# live-build/debootstrap sejam da mesma versão do Debian da ISO.
ARG DEBIAN_CODENAME=trixie
FROM debian:${DEBIAN_CODENAME}

COPY install-dependencias.sh /tmp/install-dependencias.sh

RUN sh /tmp/install-dependencias.sh \
    && rm -rf /var/lib/apt/lists/* /tmp/install-dependencias.sh

WORKDIR /src
