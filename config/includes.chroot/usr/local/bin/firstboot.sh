#!/bin/bash

#configura o os-release
cat <<EOF > /etc/os-release
PRETTY_NAME="Speedy Linux 7.0"
NAME="Speedy Linux"
VERSION_ID="7"
VERSION="7.0"
VERSION_CODENAME=speedy
ID=speedy
ID_LIKE=debian
HOME_URL="https://www.speedylinux.com.br"
EOF

cat <<EOF > /etc/lsb-release
DISTRIB_ID=Speedy
DISTRIB_RELEASE=7.0
DISTRIB_CODENAME=speedy
DISTRIB_DESCRIPTION="Speedy Linux 7.0"
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
