# SpeedyLinux

Configuração do [live-build](https://live-team.pages.debian.net/live-manual/) para gerar
a ISO live do Speedy Linux, com base no Debian, GNOME e Calamares. A partir da ISO, o usuário
usa o sistema direto do pendrive/DVD ou o instala na máquina pelo atalho "Instalar Speedy Linux".

## Passo a passo para uma nova versão

1. Altere a versão (e, se for o caso, a base Debian) no [`os-release`](os-release).
2. Substitua as imagens que mudaram na pasta [`images/`](images), mantendo os nomes.
3. Gere a ISO com `./docker-build.sh` (qualquer sistema) ou `./build.sh` (Debian).
4. A ISO fica em `dist/speedylinux-<versão>-<arch>.iso`.

## 1. Configurar o os-release

A versão do Speedy Linux e a base Debian ficam **só** no arquivo [`os-release`](os-release):

```sh
NAME="Speedy Linux"
VERSION_ID="7.1"                # versão
VERSION="7.1"                   # versão
PRETTY_NAME="Speedy Linux 7.1"  # nome completo, com a versão
VERSION_CODENAME=trixie         # base Debian: trixie = 13, forky = 14
ID=speedy
ID_LIKE=debian
HOME_URL="https://www.speedylinux.com.br"
SUPPORT_URL="https://speedysistemas.com.br"
```

- **Nova versão:** altere `VERSION_ID`, `VERSION` e `PRETTY_NAME`. A build usa esses campos
  no `/etc/os-release` e no `/etc/lsb-release` da distro, no branding do Calamares, no menu do
  GRUB e no nome da ISO.
- **Nova base Debian:** altere `VERSION_CODENAME`. Ele define o Debian da ISO e o do container
  do `docker-build.sh`. Ao trocar, confira se os pacotes de `config/package-lists/` ainda existem
  na nova versão (principalmente os de firmware); se algum não existir, a build falha e mostra qual.

Mantenha o formato do arquivo: `CHAVE=valor`, sem usar variáveis.

## 2. Alterar as imagens

As imagens ficam **só** na pasta [`images/`](images). A build copia cada uma para o destino:

| Arquivo | Uso | Destino na ISO |
|---|---|---|
| `logo.png` | Logo do Calamares e da distro | `/usr/share/speedy/logo.png`, branding do Calamares |
| `welcome.png` | Tela de boas-vindas e slideshow do Calamares | branding do Calamares |
| `wallpaper.png` | Papel de parede do GNOME | `/usr/share/speedy/wallpaper.png` |
| `installer.png` | Ícone do atalho "Instalar Speedy Linux" (256x256) | `/usr/share/icons/hicolor/256x256/apps/speedy-installer.png` |
| `avatar.png` | Foto padrão dos usuários | `/etc/skel/.face` |

Para trocar uma imagem, substitua o arquivo **mantendo o nome**. Não precisa mexer em `config/`.

O `wallpaper.png` (3840x2160) e o `welcome.png` (2048x1280) são gerados por
[`tools/gerar-imagens.py`](tools/gerar-imagens.py), que desenha o logo em vetor no estilo da distro.
Para ajustar (cores, tamanho do logo, texto), edite o script e rode:

```sh
./tools/gerar-imagens.sh   # usa Docker; grava em images/
```

## 3. Gerar a ISO

As arquiteturas suportadas são `amd64` e `arm64`.

### Com Docker (macOS, Linux ou Windows)

Só precisa do Docker instalado e rodando.

```sh
./docker-build.sh              # arquitetura do Docker (num Mac Apple Silicon: arm64)
ARCH=amd64 ./docker-build.sh   # outra arquitetura (emulada: bem mais lento)
./docker-build.sh clean        # apaga o volume de build e o cache de pacotes
```

- Na primeira execução, o script monta a imagem `speedylinux-builder:<debian>-<arch>` com as
  ferramentas de build.
- O trabalho do live-build fica no volume do Docker `speedy-build-<debian>-<arch>` (ex.:
  `speedy-build-trixie-arm64`), porque o chroot não funciona em pastas compartilhadas com o macOS.
- Reserve uns 20 GB de disco para o Docker.

### Direto num Debian

```sh
./install-dependencias.sh   # uma vez
./build.sh                  # pede sudo
```

- `ARCH=arm64 ./build.sh` força a arquitetura (padrão: a do host).
- `./clean.sh` limpa a última build e mantém o cache de pacotes.
- `./clean-build.sh` apaga tudo, inclusive o cache, e gera a ISO do zero.
- Prefira um host da mesma versão do Debian da base (ou use o Docker): o live-build de uma
  versão antiga pode não conhecer a mais nova.

### Cache

A primeira build baixa todos os pacotes e é demorada. As seguintes reaproveitam o sistema base
e os pacotes já baixados (só baixam atualizações), então ficam bem mais rápidas.

Alterar a versão ou as imagens **não** apaga o cache. Ele só é descartado com
`./docker-build.sh clean` / `./clean-build.sh`, ou ao trocar a base Debian ou a arquitetura.

## Outras personalizações

| O quê | Onde |
|---|---|
| Pacotes instalados | `config/package-lists/speedy.list.chroot` |
| Padrões do GNOME (wallpaper, teclado, favoritos, bloqueio de tela) | `config/includes.chroot/etc/dconf/db/local.d/00-speedy` |
| Calamares (cores, URLs, slideshow) | `config/includes.chroot/usr/share/speedy/calamares/branding/speedy/` |
| Menu de boot da ISO | `config/includes.binary/boot/grub/grub.cfg` |
| Hostname, locale, Plymouth | `config/hooks/normal/01-speedy.hook.chroot` |
| Usuário do live | `config/includes.chroot/etc/live/config.conf.d/10-user.conf` |

## Estrutura

- `os-release` – versão e base Debian
- `images/` – imagens da distro
- `tools/gerar-imagens.sh` + `.py` – geram o wallpaper e a tela de boas-vindas
- `build.sh` – gera a ISO (Linux)
- `docker-build.sh` + `Dockerfile` – rodam o `build.sh` num container Debian
- `install-dependencias.sh` – ferramentas de build (host Debian e container)
- `config/package-lists/` – pacotes instalados na ISO
- `config/hooks/normal/01-speedy.hook.chroot` – configurações aplicadas dentro do sistema
- `config/hooks/normal/02-grub.hook.binary` – preenche o `grub.cfg` com o kernel da build
- `config/includes.chroot/` – arquivos copiados para o sistema
- `config/includes.binary/` – arquivos copiados para a ISO (menu do GRUB)
- `config/includes.chroot/usr/local/bin/firstboot.sh` – remove o instalador no primeiro boot do sistema instalado
