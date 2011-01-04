#!/bin/bash
###########
#
# Fichier module pour configuration chroot Xephyr avec gnome
#
## regenere fichier sources.list et on met a jour les sources
if [ ! -e /usr/bin/zenity ];then
sudo aptitude -y install zenity
fi
cd /usr/local/bin
sudo rm /usr/local/bin/ubusrc-gen
sudo cp /usr/share/ubukey/scripts/ubusrc-gen /usr/local/bin/
sudo chmod +x ubusrc-gen

cd /usr/share/ubukey/scripts

sudo ubusrc-gen | zenity --progress --pulsate --title="Update des sources" --text="Regenere le fichier sources.list et cle gpg des depots" --auto-close

zenity --info --text "Lancement du gestionnaire de modules ubukeymaker, choisissez vos modules à executer"
./ubukey-addons_manager.sh

zenity --info --text "Lancement du gestionnaire de paquets synaptic, choisissez, installez, ou supprimez des logiciels"
sudo synaptic

zenity --info --text "Lancement du selecteur de langues, choisissez..."
gnome-language-selector

zenity --info --text "Lancement du panneau de controle xfce4, configurez tout ce que vous voulez , fermez la fenetre seulement une fois terminé (attention)"
xfce-setting-show

zenity --info --text "Lancement de Thunar, configurez le...(simple click par exemple)"
thunar

zenity --info --text "Lancement de chromium, pareil chargez vos themes, plugins, configurez vos bookmarks importes precedement etc etc"
killall -9 chromium-browser
chromium-browser 

## icone poste de travail
if  [[ `gconftool-2 --get /apps/nautilus/desktop/computer_icon_visible` == false ]]; then
zenity --question --title "affichage icones sur le bureau" --text "Voulez vous l icone poste de travail sur le bureau ?"
case $? in
0) gconftool-2 --set --type boolean /apps/nautilus/desktop/computer_icon_visible true ;;
1) echo  "ok, on passe" ;;
esac
fi
## icone Home
if  [[ `gconftool-2 --get /apps/nautilus/desktop/home_icon_visible` == false ]]; then
zenity --question --title "affichage icones sur le bureau" --text "Voulez vous l icone Home (direct sur votre repertoire utilisateur) sur le bureau ?"
case $? in
0) gconftool-2 --set --type boolean /apps/nautilus/desktop/home_icon_visible true ;;
1) echo  "ok, on passe" ;;
esac
fi
## Corbeille
if  [[ `gconftool-2 --get /apps/nautilus/desktop/trash_icon_visible` == false ]]; then
zenity --question --title "affichage icones sur le bureau" --text "Voulez vous afficher la poubelle sur le bureau ?"
case $? in
0) gconftool-2 --set --type boolean /apps/nautilus/desktop/trash_icon_visible true ;;
1) echo  "ok, on passe" ;;
esac
fi
## volumes visibles
if  [[ `gconftool-2 --get /apps/nautilus/desktop/home_icon_visible` == true ]]; then
zenity --question --title "affichage icones sur le bureau" --text "Voulez vous desactiver l affichage des disques montes sur le bureau ?"
case $? in
0) gconftool-2 --set --type boolean /apps/nautilus/desktop/volumes_visible false	;;
1) echo  "ok, on passe" ;;
esac
fi

zenity --info --text "Assistant de customisation terminé

Cliquez l'icône \"Quitter chroot\"  présent sur le Bureau pour sortir du chroot
et revenir à votre session locale une fois terminé ..."

exit 0
