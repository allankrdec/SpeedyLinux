# SpeedyLinux

Configuração do [live-build](https://live-team.pages.debian.net/live-manual/) para gerar
a ISO live/instaladora do Speedy Linux, com base no Debian, GNOME e Calamares.

## Gerar a ISO

A ISO é gravada em `dist/speedylinux-<versão>-<arch>.iso`. As arquiteturas suportadas são
`amd64` e `arm64`.

### Com Docker (macOS, Linux ou Windows)

Só precisa do Docker instalado e rodando.

```sh
./docker-build.sh              # arquitetura do Docker (num Mac Apple Silicon: arm64)
ARCH=amd64 ./docker-build.sh   # outra arquitetura (emulada: bem mais lento)
./docker-build.sh clean        # apaga o volume de build e o cache de pacotes
```

O trabalho do live-build fica no volume do Docker `speedy-build-<arch>`, que guarda o cache
de pacotes entre builds. Reserve uns 20 GB de disco para o Docker.

### Direto num Debian

```sh
./install-dependencias.sh   # uma vez
./build.sh
```

- `ARCH=arm64 ./build.sh` força a arquitetura (padrão: a do host).
- `./clean.sh` limpa a última build e mantém o cache de pacotes.
- `./clean-build.sh` apaga tudo, inclusive o cache, e gera a ISO do zero.

## Versão

A versão fica **só** no arquivo [`os-release`](os-release). Para lançar uma nova versão, altere
`VERSION_ID`, `VERSION` e `PRETTY_NAME`. O build usa esse arquivo para o `/etc/os-release`,
o `/etc/lsb-release`, o branding do Calamares, o menu do GRUB e o nome da ISO.

## Base Debian

A versão do Debian também fica **só** no [`os-release`](os-release), no `VERSION_CODENAME`
(`trixie` = Debian 13, `forky` = Debian 14). Ela define o Debian da ISO e o do container do
`docker-build.sh`. Ao trocar de versão, confira se os nomes dos pacotes em
`config/package-lists/` ainda existem na nova versão (principalmente os de firmware).

Rodando o `build.sh` direto num host Debian, prefira um host da mesma versão da base (ou use o
Docker): o live-build/debootstrap de uma versão antiga pode não conhecer a mais nova.

## Imagens

As imagens ficam **só** na pasta [`images/`](images). O `build.sh` copia cada uma para o destino:

| Arquivo | Uso | Destino na ISO |
|---|---|---|
| `logo.png` | Logo do Calamares e da distro | `/usr/share/speedy/logo.png`, branding do Calamares |
| `welcome.png` | Tela de boas-vindas e slideshow do Calamares | branding do Calamares |
| `wallpaper.png` | Papel de parede do GNOME | `/usr/share/speedy/wallpaper.png` |
| `installer.png` | Ícone do atalho "Instalar Speedy Linux" | `/usr/share/icons/hicolor/256x256/apps/speedy-installer.png` |
| `avatar.png` | Foto padrão dos usuários | `/etc/skel/.face` |

Para trocar uma imagem, basta substituir o arquivo mantendo o nome.

## Estrutura

- `build.sh` – gera a ISO (Linux)
- `docker-build.sh` + `Dockerfile` – rodam o `build.sh` num container Debian

- `config/package-lists/` – pacotes instalados na ISO
- `config/hooks/normal/01-speedy.hook.chroot` – configurações aplicadas dentro do sistema (os-release, locale, Calamares, Plymouth)
- `config/hooks/normal/02-grub.hook.binary` – preenche o `grub.cfg` com o kernel da build
- `config/includes.chroot/` – arquivos copiados para o sistema
- `config/includes.binary/` – arquivos copiados para a ISO (menu do GRUB)
