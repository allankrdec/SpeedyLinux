#!/bin/bash

# Se for LIVE, não faz nada
if [ -d /run/live ]; then
    echo "Rodando no LIVE, pulando firstboot"
    exit 0
fi

echo "Executando firstboot no sistema instalado..."

rm -f /usr/share/applications/speedy-installer.desktop
rm -f /usr/share/applications/calamares.desktop
rm -f /home/*/Desktop/*speedy*.desktop

# outras configs...
sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Speedy Linux 1.0"/' /etc/os-release
sed -i 's/^NAME=.*/NAME="Speedy Linux"/' /etc/os-release

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
