# SpeedyLinux

Configuração do [live-build](https://live-team.pages.debian.net/live-manual/) para gerar
a ISO live/instaladora do Speedy Linux, com base no Debian 13 (trixie), GNOME e Calamares.

## Gerar a ISO

```sh
./install-dependencias.sh   # uma vez, no host Debian
./build.sh                  # gera dist/speedylinux-<versão>-<arch>.iso
```

- `ARCH=arm64 ./build.sh` força a arquitetura (padrão: a do host; suporta `amd64` e `arm64`).
- `./clean.sh` limpa a última build e mantém o cache de pacotes.
- `./clean-build.sh` apaga tudo, inclusive o cache, e gera a ISO do zero.

## Versão

A versão fica **só** no arquivo [`os-release`](os-release). Para lançar uma nova versão, altere
`VERSION_ID`, `VERSION` e `PRETTY_NAME`. O build usa esse arquivo para o `/etc/os-release`,
o `/etc/lsb-release`, o branding do Calamares, o menu do GRUB e o nome da ISO.

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

- `config/package-lists/` – pacotes instalados na ISO
- `config/hooks/normal/01-speedy.hook.chroot` – configurações aplicadas dentro do sistema (os-release, locale, Calamares, Plymouth)
- `config/hooks/normal/02-grub.hook.binary` – preenche o `grub.cfg` com o kernel da build
- `config/includes.chroot/` – arquivos copiados para o sistema
- `config/includes.binary/` – arquivos copiados para a ISO (menu do GRUB)
