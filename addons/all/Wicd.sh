#!/bin/bash
###########
# Permet d'installer wicd et de l ajouer a l autostart , toutes distribs...
# 
DESCRIPTION="Permet d'installer Wicd (Très bon gestionnaire de connexion) "
DIST="$(lsb_release -cs)"
## ajout des depots
sudo sed -i '/wicd/d' /etc/apt/sources.list 
echo "deb http://apt.wicd.net $DIST extras" | sudo tee -a /etc/apt/sources.list
wget -q http://apt.wicd.net/wicd.gpg -O- | sudo apt-key add -

echo ""
echo -e "Ajout du dépôt et Téléchargement"
sleep 2
sudo apt-get update &>/dev/null
sudo apt-get -y --force-yes install --reinstall python-dbus wicd

echo ""
echo -e "Mise en place de l'autostart\n"
sleep 2
sudo rm /etc/xdg/autostart/*network* &>/dev/null
sudo rm /etc/xdg/autostart/nm-applet.desktop &>/dev/null

if [ ! -e "/etc/xdg/autostart/wicd.desktop" ]; then

echo -e "[Desktop Entry]
Type=Application
Encoding=UTF-8
Version=1.0
Name=Wicd
Name[fr_FR]=Wicd
Comment[fr_FR]=Gestionnaire de connexion wifi/filaire Wicd
Comment=Gestionnaire de connexion wifi/filaire Wicd
Exec='wicd-client -n'
X-GNOME-Autostart-enabled=true" | sudo tee /etc/xdg/autostart/wicd.desktop &>/dev/null

fi

echo -e "met a jour le fichier init avec Wicd \n"
sudo sed -i 's/NetworkManager/wicd/g' /usr/share/initramfs-tools/scripts/casper-bottom/23networking

echo "Installation terminée !"
sleep 5

zenity --info --title "Fin de l'installation" \
--text "Opérations terminées, validez pour continuer."
kill -9 `ps aux | grep -e [x]term | grep -e "/usr/share/ubukey/addons" | awk '{print $2}' | xargs`
