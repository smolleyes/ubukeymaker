#!/bin/bash

if [ -e "/usr/share/ubukey" ]; then 
    UBUKEYDIR="/usr/share/ubukey"
elif [ -e "/usr/local/share/ubukey" ]; then
    UBUKEYDIR="/usr/local/share/ubukey"
fi
MENU= ''

function select_webbrowser(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--titre "Paquets supplémentaires" \
--text "Choisissez votre navigateur internet:" \
--column="État" --column "Nom" \
FALSE firefox \
FALSE "chromium-browser chromium-codecs-ffmpeg-extra chromium-browser-l10n" \
FALSE opera \
FALSE midori \
'
}

function select_mail(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--titre "Paquets supplémentaires" \
--text "Choisissez votre gestionnaire de courriels:" \
--column="État" --column "Nom" \
FALSE thunderbird \
FALSE evolution \
'
}

function select_media(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--titre "Paquets supplémentaires" \
--text "Choisissez vos lecteurs multimédia:" \
--column="État" --column "Nom" \
FALSE rhythmbox \
FALSE banshee \
FALSE exaile \
FALSE totem \
FALSE vlc \
FALSE mplayer \
'
}

function select_textedit(){
MENU='#!/bin/bash
zenity --list --checklist \
--width 800 --height 600 \
--titre "Paquets supplémentaires" \
--text "Choisissez votre éditeur de texte:" \
--column="État" --column "Nom" \
FALSE gedit \
FALSE kate \
FALSE geany \
FALSE leafpad \
FALSE mousepad \
'
}

function install_packages(){
echo -e "$MENU" | tee /tmp/pchooser &>/dev/null

sudo chmod +x /tmp/pchooser
rm /tmp/List
bash /tmp/pchooser > /tmp/List

list=$(cat /tmp/List | sed 's/|/ /g' | xargs)
echo $list
case $? in
    0)
    chroot "$DISTDIR"/chroot aptitude -y install $list
    ;;
    1)
    exit 1
    ;;
esac
}

select_webbrowser
install_packages
select_mail
install_packages
select_media
install_packages
select_textedit
install_packages
