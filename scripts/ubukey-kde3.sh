#!/bin/bash
###########
#
# Fichier module pour configuration chroot avec kde3
#
## regenere fichier sources.list et on met a jour les sources

cd /usr/local/bin
rm /usr/local/bin/ubusrc-gen
wget http://www.ubukey.fr/files/ubusrc-gen
chmod +x ubusrc-gen

ubusrc-gen && killall -9 zenity &
zenity --info --title "Update des sources" --text "Regenere le fichier sources.list et cle gpg des depots, patientez svp"

if [ ! -e /usr/bin/mkpasswd ]; then
apt-get -y install whois
fi

MENU=$(zenity --list --width 500 --height 250 \
--text "choisissez les operations à effectuer
" \
--checklist --column "" --column "Action" --column "Description" --hide-column 0 \
FALSE "Addons" "Démarre le gestionnaire de modules du script" \
FALSE "Adept" "Adept pour choisir, installer/desinstaller vos logiciels" \
FALSE "Kde" "Executera une serie d actions, lancement de konqueror
dolphin, du centre de controle kde...")

CHOICE=$(echo -e "$MENU" | sed 's/|/ /g')
for i in $CHOICE; do 
case $i in

Addons)
ubukey-addons_manager.sh
;;

Adept)
adept_manager
;;

Kde)
zenity --question --text "Voulez-vous lancer le panneau de controle kde, configurer tout ce que vous voulez et fermez la fenetre une fois terminé si oui "
case $? in
0)
kcontrol
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

zenity --question --text "Voulez-vous lancer Konqueror, configurez le...(simple click par exemple) si oui"
case $? in
0)
konqueror
;;
1)
;;
esac
;;

esac ## fin case menu
done ## fin for menu

sleep 2

zenity --info --text "Assistant de customisation terminé

Cliquez l'icône \"Quitter chroot\"  présent sur le Bureau pour sortir du chroot
et revenir à votre session locale une fois terminé ..."

exit 0
