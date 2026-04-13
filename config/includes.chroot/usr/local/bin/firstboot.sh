#!/bin/bash

#configura o os-release
cat <<EOF > /etc/os-release
PRETTY_NAME="Speedy Linux 7.0"
NAME="Speedy Linux"
VERSION_ID="13"
VERSION="13 (trixie)"
VERSION_CODENAME=trixie
DEBIAN_VERSION_FULL=13.4
ID=debian
HOME_URL="https://www.speedylinux.com.br"

EOF

# Se for LIVE, não faz nada
if [ -d /run/live ]; then
    echo "Rodando no LIVE, pulando firstboot"
    exit 0
fi

echo "Executando firstboot no sistema instalado..."

chmod 644 /usr/share/speedy/logo.png
cp /usr/share/speedy/logo.png /etc/skel/.face
chmod 644 /etc/skel/.face

#remove instaladores
rm -f /usr/share/applications/speedy-installer.desktop
rm -f /usr/share/applications/calamares.desktop
rm -f /home/*/Desktop/*speedy*.desktop


systemctl disable firstboot.service
rm -f /etc/systemd/system/firstboot.service

exit 0

echo "Configurando logo do GDM..."

cat <<EOF > /etc/gdm3/greeter.dconf-defaults
[org/gnome/login-screen]
#logo='/usr/share/speedy/logo.png'
enabled-smartcard-authentication=false

[org/gnome/settiings-daemon/plugin/power]

EOF

dconf update
