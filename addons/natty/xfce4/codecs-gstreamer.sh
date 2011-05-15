#!/bin/bash
###########
#
# Template a suivre pour les autres modules... utilisez toujours "xterm -e" et/ou zenity pour # lancer/afficher vos scripts 
#
###########
# Celui-Permet d'installer les paquets gstreamer
# 

DESCRIPTION="Permet d'installer les codecs Gstreamer (bad,ugly...)
w32codecs, libdvdcss2 et flasplugin 10..."

echo -e "Vérification des sources et mise à jour si besoin...\n"
sleep 2
ver=$(lsb_release -cs)
## efface entree au cas ou deja là.. 
sed -i '/medibuntu/d' /etc/apt/sources.list
wget -q http://packages.medibuntu.org/medibuntu-key.gpg -O- | sudo apt-key add - &>/dev/null
## et reinjecte
echo "deb http://packages.medibuntu.org/ $ver free non-free" | tee -a /etc/apt/sources.list
apt-get update &>/dev/null

echo -e "Installation des codecs gstreamer flash etc... \n"
sleep 3

apt-get update

aptitude -y install w32codecs libflashsupport libdvdcss2 gstreamer0.10-alsa gstreamer0.10-ffmpeg gstreamer0.10-fluendo-mp3 gstreamer0.10-fluendo-mpegdemux gstreamer0.10-fluendo-mpegmux gstreamer0.10-gnomevfs gstreamer0.10-plugins-bad gstreamer0.10-plugins-bad-multiverse gstreamer0.10-plugins-base gstreamer0.10-plugins-base-apps gstreamer0.10-plugins-good gstreamer0.10-plugins-ugly gstreamer0.10-plugins-ugly-multiverse gstreamer0.10-pulseaudio gstreamer0.10-tools

if [[ `dpkg -l | grep "flashplugin-nonfree"` ]]; then
aptitude purge flashplugin-nonfree
fi

echo -e "Téléchargement du deb adobe à jour pour flashplayer..."
cd /tmp
wget http://fpdownload.macromedia.com/get/flashplayer/current/install_flash_player_10_linux.deb
dpkg -i install_flash_player_10_linux.deb

echo -e "\nCodecs installés... \n"
sleep 3 

zenity --info --title "Fin de l'installation" \
--text "Opérations terminées, validez pour continuer."
kill -9 `ps aux | grep -e "root" | grep -e [x]term | grep -e "/usr/local/bin/ubukey-addons" | awk '{print $2}' | xargs`
