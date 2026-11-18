# SpeedyLinux: notas para o Claude

Distro baseada em Debian (live-build + GNOME + instalador Calamares). O uso
e a estrutura estão no `README.md`. Aqui ficam as regras de trabalho e os
detalhes que não são óbvios e já causaram bugs.

## Regras de trabalho

- **Nunca dar `git push`.** Fazer o commit local e parar; o usuário faz o push.
- Responder e escrever commits, comentários e docs em português.
- Testar primeiro no **arm64**: a build é nativa no Mac do usuário (Apple
  Silicon, ~20–30 min) e o teste é no Parallels. O amd64 é emulado (1,5 a 4 h)
  e é testado num PC de verdade, por pendrive.
- Só commitar mudanças de build depois que o usuário testar a ISO.

## Build

- `./docker-build.sh` gera a ISO da arquitetura do Docker;
  `ARCH=amd64 ./docker-build.sh` gera a outra (emulada). A ISO sai em `dist/`.
- O diretório de trabalho do live-build é um **volume do Docker**
  (`speedy-build-<debian>-<arch>`), porque o chroot não funciona em pasta
  compartilhada com o macOS nem no HD externo.
- Para inspecionar uma build: o `build/chroot` do volume não reflete tudo
  (os archives do binary são removidos depois do squashfs). Confira
  `build/binary/live/filesystem.squashfs` com `unsquashfs` (dá para extrair só
  alguns caminhos).
- O pool do d-i é baixado de novo em toda build (não fica em cache).

## Por que as coisas são assim

- **`--debian-installer live` precisa ficar.** O passo `sources-media` do
  Calamares usa `file:/run/live/medium` como fonte do apt, e o
  `bootloader-config` instala `grub-efi`/`grub-pc` desse pool. As entradas do
  d-i não aparecem porque o `grub.cfg` é customizado.
- **`--firmware-binary false`**: tira do pool do d-i uns 360 MB de firmwares
  que só o d-i usaria. Os firmwares continuam no live e no sistema instalado
  (`--firmware-chroot` instala todos os pacotes de firmware do Debian).
- **Kernel:** o live-build copia como `live/vmlinuz-<versão>` (nunca
  `vmlinuz`), por isso o `grub.cfg` usa `@KERNEL@`/`@INITRD@`, preenchidos pelo
  hook `02-grub.hook.binary` (hooks binary rodam com cwd em `build/binary`).
- **Locale/ç:** o live-config grava `LANG=en_US.UTF-8` no boot se não houver
  `locales=` na linha do kernel. Com en_US, `'`+`c` vira ć no teclado US intl.
  Por isso o `grub.cfg` tem `locales=pt_BR.UTF-8`.
- **Teclado:** nunca definir `org/gnome/desktop/input-sources` no dconf. O
  GNOME passa a ignorar o teclado que o Calamares grava em
  `/etc/default/keyboard`. O teclado do live vem de `keyboard-layouts=` no boot.
- **Backports:** o kernel e os firmwares vêm do `<codename>-backports` (o
  RTL8811AU, por exemplo, só funciona a partir do 6.13). O `build.sh` gera
  `config/archives/speedy-backports.pref` com pin 990 só para `linux-*`
  (incluindo `linux-base`, que o kernel bpo exige) e `firmware-*`. O
  Calamares (`sources-final`) já grava o backports no `sources.list` do
  sistema instalado, então ele continua recebendo o kernel por lá.
  `BACKPORTS=false` gera com o kernel estável. Não colocar o kernel estável
  junto: o conflito de meta-pacotes faria ele ficar sem atualização.
- **Sem DKMS:** drivers de fora do kernel quebram com atualizações do kernel e
  com Secure Boot. Rede/Wi-Fi tem que funcionar de fábrica; o resto pode ser
  baixado depois.
- **`cryptsetup`, `cryptsetup-initramfs` e `btrfs-progs` ficam na lista de
  pacotes:** o Calamares remove os próprios pacotes e roda
  `apt-get --purge autoremove`; sem estarem na lista, eles seriam purgados e
  um sistema com criptografia ou em btrfs não daria boot.
- **Hook `98-firmware-servidor`:** remove firmwares de datacenter
  (netronome, marvell-prestera, nvidia-tesla-gsp) e regera o initrd.
- O aviso `dpkg-divert ... /usr/lib/os-release` ("Essential package with
  rename is dangerous") é inofensivo.

## Armadilhas ao investigar

- Simulando o apt em container Docker: a imagem `debian` traz
  `/etc/apt/apt.conf.d/docker-autoremove-suggests`
  (`SuggestsImportant false`), o que cria falsos "órfãos" (mdadm, kpartx,
  kbd, binutils…). Sempre `rm /etc/apt/apt.conf.d/docker-*` e usar
  `--platform linux/<arch>` igual ao da ISO (a imagem em cache pode ser da
  outra arquitetura). Isso já levou a um diagnóstico errado.
- Fotos de tela do usuário chegam em `.HEIC`: converter com
  `sips -s format jpeg` antes de ler.

## Pendências conhecidas

- O initrd do live tem ~220 MB (~400 MB descompactado, quase tudo firmware de
  GPU: NVIDIA GSP, que o kernel 7.x puxa, e amdgpu). VM com 1 GB de RAM dá
  kernel panic "Failed to execute /init (error -2)"; com 4 GB funciona. Tirar
  o firmware de GPU do initrd é arriscado (amdgpu/nouveau no initrd falham
  sem ele).
- Boot BIOS (legado) e instalação com `grub-pc` nunca foram testados.
- O Calamares falhou uma vez com `apt-get --purge autoremove` código 100
  (amd64, VirtualBox) e não voltou a acontecer. Se voltar, o log está em
  `/root/.cache/calamares/session.log`.
