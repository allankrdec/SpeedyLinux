# locale
export LANG=pt_BR.UTF-8
export LANGUAGE=pt_BR
export LC_ALL=pt_BR.UTF-8

# wallpaper
gsettings set org.gnome.desktop.background picture-uri file:///usr/share/speedy/wallpaper.png 2>/dev/null
gsettings set org.gnome.desktop.background picture-uri-dark file:///usr/share/speedy/wallpaper.png 2>/dev/null

# teclado
gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'br')]" 2>/dev/null

# desativar lock
gsettings set org.gnome.desktop.screensaver lock-enabled false 2>/dev/null
gsettings set org.gnome.desktop.session idle-delay 0 2>/dev/null

gsettings set org.gnome.system.locale region 'pt_BR.UTF-8' 2>/dev/null

# Atalho para instalador
gsettings set org.gnome.shell favorite-apps "[
'org.gnome.Nautilus.desktop',
'org.gnome.Terminal.desktop',
'speedy-installer.desktop'
]" 2>/dev/null
