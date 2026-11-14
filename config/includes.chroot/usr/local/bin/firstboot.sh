#!/bin/sh
# Roda uma única vez no sistema instalado: remove os atalhos do instalador.
# (os-release/lsb-release agora são gerados na build, pelo hook 01-speedy)

# Se for LIVE, não faz nada
if [ -d /run/live ]; then
    echo "Rodando no LIVE, pulando firstboot"
    exit 0
fi

echo "Executando firstboot no sistema instalado..."

# remove instaladores
rm -f /usr/share/applications/speedy-installer.desktop
rm -f /usr/share/applications/calamares.desktop
rm -f /home/*/Desktop/*speedy*.desktop
rm -f /home/*/"Área de Trabalho"/*speedy*.desktop

systemctl disable firstboot.service
rm -f /etc/systemd/system/firstboot.service

exit 0
