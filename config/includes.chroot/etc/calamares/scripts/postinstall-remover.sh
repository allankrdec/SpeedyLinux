#!/bin/bash

echo "Removendo instalador do sistema final..."

rm -f /usr/share/applications/calamares.desktop
rm -f /home/*/Desktop/*calamares*.desktop

echo "Aplicando branding..."

sed -i 's/^PRETTY_NAME=.*/PRETTY_NAME="Speedy Linux 1.0"/' /etc/os-release
sed -i 's/^NAME=.*/NAME="Speedy Linux"/' /etc/os-release

plymouth-set-default-theme spinner
update-initramfs -u

exit 0
