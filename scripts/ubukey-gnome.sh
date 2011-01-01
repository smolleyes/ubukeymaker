#!/bin/bash
###########
#
# Fichier module pour configuration chroot Xephyr avec gnome
#
## regenere fichier sources.list et on met a jour les sources
sudo /bin/bash /usr/share/ubukey/scripts/ubusrc-gen | zenity --progress --pulsate --title="Update des sources" --text="Regenere le fichier sources.list et cle gpg des depots" --auto-close

MENU=$(zenity --list --width 600 --height 425 \
--text "choisissez les operations à effectuer
" \
--checklist --column "" --column "Action" --column "Description" --hide-column 0 \
FALSE "Addons" "Démarre le gestionnaire de modules du script" \
FALSE "Synaptic" "Synaptic pour choisir, installer/desinstaller vos logiciels" \
FALSE "Gnome" "Executera une serie d actions, lancement de nautilus
, du centre de controle gnome etc ")

CHOICE=$(echo -e "$MENU" | sed 's/|/ /g')
for i in $CHOICE; do 
case $i in
Addons)
zenity --info --text "Lancement du gestionnaire de modules ubukeymaker, choisissez vos modules à executer"
/bin/bash /usr/share/ubukey/scripts/ubukey-addons_manager.sh
;;

Synaptic)
zenity --info --text "Lancement du gestionnaire de paquets synaptic, choisissez, installez, ou supprimez des logiciels"
sudo synaptic
;;

Gnome)
zenity --info --text "Lancement du Panneau de configuration gnome, effectuez tous vos réglages
une fois terminé fermez la fenêtre."
gnome-control-center

zenity --info --text "Lancement de nautilus, configurez le (simple click, fond etc...)"
nautilus

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
;;

1)
;;
esac
done


sleep 2

zenity --info --text "Assistant de customisation terminé

Cliquez l'icône \"Quitter chroot\"  présent sur le Bureau pour sortir du chroot
et revenir à votre session locale une fois terminé ..."

exit 0
