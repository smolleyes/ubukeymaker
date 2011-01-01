#!/bin/bash
###########
#
# Fichier module pour configuration chroot Xephyr avec gnome
#
## regenere fichier sources.list et on met a jour les sources

sudo /bin/bash /usr/share/ubukey/scripts/ubusrc-gen && killall -9 zenity &
zenity --info --title "Update des sources" --text "Regenere le fichier sources.list et cle gpg des depots, patientez svp (ne cliquez PAS sur ok...!)"

if [ ! -e /usr/bin/mkpasswd ]; then
sudo apt-get -y install whois
fi

zenity --question --text "Voulez vous lancer le gestionnaire de modules ubukeymaker pour kde4 ..."
case $? in
0)
/bin/bash /usr/share/ubukey/scripts/ubukey-addons_manager.sh
;;
1)
;;
esac

zenity --question --text "Voulez-vous Lancer le gestionnaire de paquets adept, choix, installation, ou suppression des logiciels"
case $? in
0)
adept_manager
;;
1)
;;
esac

zenity --question --text "Voulez-vous lancer le panneau de controle kde, configurer tout ce que vous voulez et fermez la fenetre une fois terminé si oui "
case $? in
0)
systemsettings
;;
1)
;;
esac

zenity --question --text "Voulez-vous lancer Dolphin, configurez le...(simple click par exemple) si oui"
case $? in
0)
dolphin
;;
1)
;;
esac

zenity --question --text "Voulez-vous lancer konqueror ?"
case $? in
0)
konqueror
;;
1)
;;
esac

sleep 2

zenity --info --text "Assistant de customisation terminé

Cliquez l'icône \"Quitter chroot\"  présent sur le Bureau pour sortir du chroot
et revenir à votre session locale une fois terminé ..."

exit 0
