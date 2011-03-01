#!/bin/bash

DISTDIR=$1
USER=$2
CURDIST=`lsb_release -cs`

if [ -e "/usr/share/ubukey" ]; then 
UBUKEYDIR="/usr/share/ubukey"
elif [ -e "/usr/local/share/ubukey" ]; then
UBUKEYDIR="/usr/local/share/ubukey"
else ## running .py
mkdir /usr/share/ubukey
cp -R 
fi

if [[ "`uname -m`" == "x86_64" ]]; then
	X64="true"
fi

function prepareChroot()
{
echo "${DISTDIR}"/chroot/etc/lsb-release
CHROOTVER=$(cat "${DISTDIR}"/chroot/etc/lsb-release | awk -F= '/CODENAME/ {print $2}')

## return if not the same distro...
if [ "${CURDIST}" != "$CHROOTVER" ]; then
	zenity --error --text "Désolé, vous êtes actuellement sur une distribution \"${CURDIST}\" 
et vous préparez une distrib $CHROOTVER.

Pour des raisons de sécurité et de conflits potentiels, ceci
n'est pas supporté.

réutilisez la même image si vous le souhaitez, mais depuis une version \"$CHROOTVER\".
"
exit 1
fi

echo -e "Préparation du chroot, merci de patienter... \n"

## synchronise fichiers locaux et distribs
if [ ! -e "${DISTDIR}"/chroot/usr/share/ubukey ]; then
mkdir "${DISTDIR}"/chroot/usr/share/ubukey
fi

if [  -n $UBUKEYDIR ]; then
rsync -uravH --delete --exclude ".git" --exclude "~" $UBUKEYDIR/. "${DISTDIR}"/chroot/usr/share/ubukey/.
chmod +x "${DISTDIR}"/chroot/usr/share/ubukey/scripts/*
fi

sessionType=$(grep -e "distSession" "${DISTDIR}"/config | sed 's/.*distSession=//')
LOCALUTF=$(env | grep -w "LANG" | sed -e 's/LANG=//' -e 's/.utf8/.UTF-8/g')
LOCALBASE=$(env | grep -w "LANG" | sed -e 's/\..*//' -e 's/LANG=//')
LOCALSIMPLE=$(env | grep -w "LANG" | sed -e 's/\..*//' -e 's/LANG=//' -e 's/_.*//')

keylayout="$LOCALSIMPLE"
cp /etc/resolv.conf "${DISTDIR}"/chroot/etc/
cp /etc/hosts "${DISTDIR}"/chroot/etc/

## scan du dossiers de conf  
if [ ! -e "${DISTDIR}"/chroot/etc/ubukey ]; then
	mkdir "${DISTDIR}"/chroot/etc/ubukey
fi
## nettoyage et recreation des sous dossiers (en cas de changements, on clean tout....)
mkdir "${DISTDIR}"/chroot/etc/ubukey/{sources,ubiquity} &>/dev/null

## copie conf
cp -f "${DISTDIR}"/config "${DISTDIR}"/chroot/etc/ubukey/ubukeyconf ## config generale
## nettoyage apt et le preparer en cas de copie des paquets locaux
apt-get clean &>/dev/null
## nettoie fichiers desinstalles mais pas la conf donc toujours apparents
dpkg -l |grep ^rc |awk '{print $2}' |xargs dpkg -P &>/dev/null 
## verifies ppa etc
if [[ `apt-get update 2>&1 | tee /tmp/t &>/dev/null && cat /tmp/t | grep "ppa.launchpad.net.*NO_PUBKEY"` ]]; then
# Simple script to check for all PPAs refernced in your apt sources and
# to grab any signing keys you are missing from keyserver.ubuntu.com.
# Additionally copes with users on launchpad with multiple PPAs
# (e.g., ~asac)
#
# Author: Dominic Evans https://launchpad.net/~oldman
# License: LGPL v2

for APT in `find /etc/apt/ -name *.list`; do
    grep -o "^deb http://ppa.launchpad.net/[a-z0-9\-]\+/[a-z0-9\-]\+" $APT | while read ENTRY ; do
        # work out the referenced user and their ppa
        USER=`echo $ENTRY | cut -d/ -f4`
        PPA=`echo $ENTRY | cut -d/ -f5`
        # some legacy PPAs say 'ubuntu' when they really mean 'ppa', fix that up
        if [ "ubuntu" = "$PPA" ]
        then
            PPA=ppa
        fi
        # scrape the ppa page to get the keyid
        KEYID=`wget -q --no-check-certificate https://launchpad.net/~$USER/+archive/$PPA -O- | grep -o "1024R/[A-Z0-9]\+" | cut -d/ -f2`
        sudo apt-key adv --list-keys $KEYID >/dev/null 2>&1
        if [ $? != 0 ]
        then
            echo Grabbing key $KEYID for archive $PPA by ~$USER
            sudo apt-key adv --recv-keys --keyserver keyserver.ubuntu.com $KEYID
        else
            echo Already have key $KEYID for archive $PPA by ~$USER
        fi
    done
done
########################################################################
fi

## copie fichiers sources et cle gpg locales
rm "${DISTDIR}"/chroot/etc/ubukey/sources/sources.list.d/private-ppa* &>/dev/null
cp -R -f /etc/apt/{sources.list,trusted.*,sources.list.d} "${DISTDIR}"/chroot/etc/apt/
cp -R -f /etc/apt/{sources.list,trusted.*,sources.list.d} "${DISTDIR}"/chroot/etc/ubukey/sources
rm "${DISTDIR}"/chroot/etc/apt/sources.list.d/private-ppa* &>/dev/null

## exporter la liste des paquets locaux
dpkg --get-selections | tee "${DISTDIR}"/chroot/etc/ubukey/sources/pkglist.selections &>/dev/null

## d abord chtite astuce
sed -i '/mode/d' "${DISTDIR}"/chroot/etc/ubukey/ubukeyconf
#sed -i 's/\/root/\/home\/'$USER'/' "${DISTDIR}"/chroot/etc/passwd
echo "user=$USER" | tee -a "${DISTDIR}"/chroot/etc/ubukey/ubukeyconf &>/dev/null
echo "keyLayout=$keylayout" | tee -a "${DISTDIR}"/chroot/etc/ubukey/ubukeyconf &>/dev/null
echo "localsimple=$LOCALSIMPLE" | tee -a "${DISTDIR}"/chroot/etc/ubukey/ubukeyconf &>/dev/null
echo "localbase=$LOCALBASE" | tee -a "${DISTDIR}"/chroot/etc/ubukey/ubukeyconf &>/dev/null
echo "localutf=$LOCALUTF" | tee -a "${DISTDIR}"/chroot/etc/ubukey/ubukeyconf &>/dev/null
echo "mode=safe" | tee -a "${DISTDIR}"/chroot/etc/ubukey/ubukeyconf &>/dev/null
cp /etc/hosts "${DISTDIR}"/chroot/etc/ -f

## determine quelle session tourne actuellement (tres chiant)
if [[ `ps aux | grep -e "[g]nome-settings-daemon" ` ]]; then
	localSession="gnome"
elif [[ `ps aux | grep -e "[k]ded4" ` && ! `ps aux | grep -e "[g]nome-settings-daemon"` ]]; then
	localSession="kde4"
elif [[ `ps aux | grep -e "[x]fsettingsd"` ]]; then
	localSession="xfce4"
elif [[ `ps aux | grep -e "[l]xsession"` ]]; then
	localSession="lxde"
else
	echo -e "Type de session locale non détéctée, ou non supportée vous utilisez e17, fluxbox ???... 
aucun thème ne sera copié"
fi

## check zenity
if [[ ! -e "${DISTDIR}/chroot/usr/bin/zenity" && ! $sessionType = "console" ]]; then
echo -e "Installation de zenity, manquant dans votre distribution $localSession"
chroot "${DISTDIR}"/chroot aptitude -y install zenity &>/dev/null
fi

if [ -z "$console" ]; then
	## assistant pre chroot inclus (copie des themes si session locale est la meme que la session a preparer)
	if [[ "$sessionType" != "$localSession" ]]; then
	echo -e "Vous utilisez \"$localSession\" actuellement et vous préparez une session \"$sessionType\" 
, copie des thèmes annulée... \n"

	elif [[ "$sessionType" = "kde4" && ! -e "${DISTDIR}"/chroot/etc/skel/.kde ]]; then
	zenity --info --text "Première execution du chroot, la copie des thèmes, des icones etc 
ne sera proposée qu'au prochain démarrage du chroot (pas encore de .kde...)

Cliquez \"Valider\" pour continuer
"
	else
		. $UBUKEYDIR/scripts/themescan.sh
	fi
fi ## fin check si mode console

## Copie des addons dans chroot/usr/local/bin/ubukey-addons
localDistVer=$(cat /etc/lsb-release | grep "DISTRIB_CODENAME" | sed 's/.*=//')
chrootDistVer=$(cat /etc/lsb-release | grep "DISTRIB_CODENAME" | sed 's/.*=//')

## check addons
update_addons

## ajoute resolution ecran local dans chroot 
#ddcprobe | grep dtiming | sed 's/.*: //;s/@.*//' > "$DISTDIR"/chroot/tmp/resolution
## effaces squashfs etc
rm -R "${DISTDIR}"/usb/casper/* &>/dev/null

### demarre le chroot
mkdir "${DISTDIR}"/chroot/dev &>/dev/null
mount -o bind /dev "${DISTDIR}"/chroot/dev &>/dev/null

rm "${DISTDIR}"/chroot/var/lib/dbus/machine-id &>/dev/null
dbus-uuidgen | tee "${DISTDIR}"/chroot/var/lib/dbus/machine-id &>/dev/null

mkdir "${DISTDIR}"/chroot/var/run/dbus &>/dev/null
mount -o rbind /var/run/dbus "${DISTDIR}"/chroot/var/run/dbus &>/dev/null

deftty="`ps ax | grep -w '[/]usr/bin/X :0' | awk '{print $2}' | sed 's/tty//'`"
rm "${DISTDIR}"/chroot/tmp/deftty &>/dev/null
echo $deftty > "${DISTDIR}"/chroot/tmp/deftty

mkdir -p "${DISTDIR}"/chroot/media/pc-local/home &>/dev/null
mkdir "${DISTDIR}"/chroot/media/pc-local/media &>/dev/null
mount -o rbind "/home/$USER" "${DISTDIR}"/chroot/media/pc-local/home
mount -o rbind "/media" "${DISTDIR}"/chroot/media/pc-local/media

doChroot

}

function update_addons()
{
## check if our distrib already have version file for addons
if [ ! -e "${WORK}/addons" ]; then
	mkdir "${WORK}/addons"
fi
cp -R -f $UBUKEYDIR/addons/{all,$CURDIST,custom} "${WORK}"/addons/ &>/dev/null

echo -e "Copie les addons du script et vos addons perso pour votre distrib $sessionType \n"

mkdir "${DISTDIR}"/chroot/usr/local/bin/ubukey-addons &>/dev/null
cp -f "${WORK}"/addons/$CHROOTVER/"$sessionType"/* "${DISTDIR}"/chroot/usr/local/bin/ubukey-addons &>/dev/null
cp -f "${WORK}"/addons/all/* "${DISTDIR}"/chroot/usr/local/bin/ubukey-addons &>/dev/null
cp -f "${WORK}"/addons/custom/* "${DISTDIR}"/chroot/usr/local/bin/ubukey-addons &>/dev/null
mv "${DISTDIR}"/chroot/etc/fstab "${DISTDIR}"/chroot/etc/fstab-save
mv "${DISTDIR}"/chroot/etc/mtab "${DISTDIR}"/chroot/etc/mtab-save
cp -R -f /etc/fstab "${DISTDIR}"/chroot/etc/ &>/dev/null
chmod +x "${DISTDIR}"/chroot/usr/local/bin/* -R &>/dev/null
chmod +x "${DISTDIR}"/chroot/$UBUKEYDIR/addons/* -R &>/dev/null

## clean dpkg
> "${DISTDIR}"/chroot/var/lib/dpkg/statoverride

}

##########################################################
## fonction chroot
function doChroot()
{

## demarre le chroot
rm "${DISTDIR}"/logs/chrootlog.log &>/dev/null
touch "${DISTDIR}"/logs/chrootlog.log &>/dev/null
rm "${DISTDIR}"/chroot/tmp/chrootlog.log &>/dev/null
touch "${DISTDIR}"/chroot/tmp/chrootlog.log &>/dev/null
rm -f "${DISTDIR}"/chroot/etc/skel/*/{ubukey-assist,quit-chroot,gc}.desktop &>/dev/null

(tail -f "${DISTDIR}"/chroot/tmp/chrootlog.log &) 2>/dev/null & chroot "$DISTDIR"/chroot &> "${DISTDIR}"/logs/chrootlog.log << "EOF"

mode="$(cat /etc/ubukey/ubukeyconf | grep -e "mode" | sed 's/.*=//')"

function message() {
touch /tmp/chrootlog.log
message="$1"
echo -e "$message" | tee -a /tmp/chrootlog.log &>/dev/null
}

function INITCHROOT()
{
if [ ! -e "/usr/share/ubukey" ] ; then
mkdir /usr/share/ubukey
fi
UBUKEYDIR="/usr/share/ubukey"
chrootKerVer=$(ls -al /initrd.img | sed 's/.*boot\/initrd.img-//')
localKerVer=$(cat /etc/ubukey/ubukeyconf | grep -e "Kernel" | sed 's/.*Kernel=//')
sessionType=$(cat /etc/ubukey/ubukeyconf | grep -e "distSession" | sed 's/.*distSession=//')
USER=$(cat /etc/ubukey/ubukeyconf | grep -e "user" | sed 's/.*user=//')
chuser=$(cat /etc/casper.conf | grep -w "USERNAME=" | sed 's/.*=//' | sed 's/"//g')
LOCALUTF="$(cat /etc/ubukey/ubukeyconf | grep -e "localutf" | sed 's/.*=//')"
LOCALBASE="$(cat /etc/ubukey/ubukeyconf | grep -e "localbase" | sed 's/.*=//')"
LOCALSIMPLE="$(cat /etc/ubukey/ubukeyconf | grep -e "localsimple" | sed 's/.*=//')"
DIST="$(cat /etc/lsb-release | grep CODENAME | sed 's/.*=//')"
DRIVER="$(cat /etc/ubukey/ubukeyconf | grep -e "driver" | sed 's/.*=//')"

if [ "$sessionType" = "console" ]; then
	sessionType="console"
	starter="xterm"
fi

## langue dans chroot
export LANG=$LOCALUTF
export LC_ALL=$LOCALUTF
echo -e "$LOCALSIMPLE
$LOCALBASE
$LOCALUTF
" | tee /etc/locale.gen &>/dev/null

message "
#########################
## Variables du chroot ##
#########################

Type de session : "$sessionType"
Utilisateur session chroot : "$USER"
Utilisateur reel du live-cd : "$chuser"
Locales : $LOCALUTF
Langue : $LOCALSIMPLE
Clavier: $LOCALSIMPLE
"

#dpkg-divert --local --rename --add /sbin/initctl
﻿#ln -s /bin/true /sbin/initctl

#monter minimun necessaire
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts

umount -f /lib/modules/*/volatile &>/dev/null

## check sources
message "Verification des sources, merci de patienter"
/bin/bash $UBUKEYDIR/scripts/themescan.sh

## Changement de la langue par defaut des consoles tty avec : $LOCALSIMPLE
sed -i 's/XKBLAYOUT=.*/XKBLAYOUT="'$LOCALSIMPLE'"/' /etc/default/console-setup

## check du decorateur et autres
case $sessionType in
gnome)
decorator="metacity"
term="gnome-terminal"
starter=gnome-session
;;
kde4)
decorator=kwin
term=konsole
starter=startkde
;;
xfce4)
decorator="xfwm4"
term="xfterm4"
starter=xfce4-session
;;
lxde)
decorator=""
term="lxterminal"
if [ -e "/usr/bin/startlubuntu" ]; then
starter="startlubuntu"
else
starter="startlxde"
fi
;;
esac

}

function CHROOTGRAPHIQUE()
{

## au cas ou
rm /etc/skel/skel &>/dev/null
rm /home/"$USER" -R &>/dev/null
ln -sf /etc/skel /home/"$USER"
cd /etc/skel


## create user and sudo
if [ ! -e '/usr/bin/sudo' ]; then
apt-get install -f --force-yes sudo
fi
useradd -s /bin/bash -M "$USER"
## check user creation
if [[ ! `cat /etc/passwd | grep -e "^$USER:"` ]]; then
message "Impossible de creer l utilisateur $USER, sortie \n"
CLEANCHROOT
exit 0
fi
## config sudo
if [[ ! `cat /etc/group | grep -e "^sudo:"` ]]; then
groupadd sudo
fi
sed -i 's/%sudo.*/%sudo ALL=NOPASSWD: ALL/' /etc/sudoers
adduser "$USER" sudo

## clean xdg
rm /home/"$USER"/.config/user-dirs.dirs &>/dev/null
rm /etc/locale.gen &>/dev/null
echo -e "$LOCALSIMPLE
$LOCALBASE
$LOCALUTF
" | tee /etc/locale.gen &>/dev/null

chmod 777 /dev/shm
chown -hR "$USER":"$USER" /etc/skel
export HOME="/home/$USER"

if [ "$sessionType" != "console" ]; then

## check paquet xdg-user-dirs
message "Detection des dossiers Xdg (Bureau, Desktop...)\n"
if [[ ! `dpkg -l | grep -e "xdg-user-dirs"` ]]; then
aptitude -y install xdg-user-dirs
fi

sudo -u "$USER" xdg-user-dirs-update 
sudo -u "$USER" xdg-user-dirs-update --force

## reverifie le users-dirs.dirs
deskdir="$(cat /home/"$USER"/.config/user-dirs.dirs | grep DESKTOP | sed 's/.*\///' | sed 's/\"//')"
if [ -z "$deskdir" ]; then
mkdir /etc/skel/Desktop
deskdir="Desktop"
fi

## check dossier bureau
if [[ ! `cat /home/"$USER"/.config/user-dirs.dirs | grep -e "/Desktop"` && -e /etc/skel/Desktop ]]; then
rm -R /etc/skel/Desktop
deskdir="$(cat /home/"$USER"/.config/user-dirs.dirs | grep DESKTOP | sed 's/.*\///' | sed 's/\"//')"
## au cas ou...
mkdir /etc/skel/$deskdir &>/dev/null
fi

##checkfinal si deskdir ok
if [ -z "$deskdir" ]; then
message "Probleme avec dossier Bureau, sortie"
CLEANCHROOT
exit 0
fi

message "Dossier bureau : $deskdir \n"

## adapte dossier Desktop, casper-bottom
if [ "$deskdir" != "Desktop" ]; then
sed -i 's/Desktop/'$deskdir'/g' /usr/share/initramfs-tools/scripts/casper-bottom/10adduser
fi

## share dir
ln -s /media/pc-local /home/"$USER"/"$deskdir"/Shared_Folder

if [ ! -e /usr/share/pixmaps/usbkey.png ]; then
cp $UBUKEYDIR/images/usbkey.png /usr/share/pixmaps/
fi

################## ajout icones sur le bureau
echo "[Desktop Entry]
Type=Application
Encoding=UTF-8
Version=1.0
Name=Assistant de customisation $sessionType
Name[fr_FR]=Assistant de customisation $sessionType
Comment[fr_FR]=Assistant de customisation pour $sessionType
Comment=Assistant de customisation pour $sessionType
Exec=$UBUKEYDIR/scripts/ubukey-$sessionType.sh
X-GNOME-Autostart-enabled=true
Icon=/usr/share/pixmaps/usbkey.png" | tee /etc/skel/"$deskdir"/ubukey-assist.desktop &>/dev/null

chmod +x /etc/skel/"$deskdir"/ubukey-assist.desktop

echo "[Desktop Entry]
Type=Application
Encoding=UTF-8
Version=1.0
Name=fix-clavier
Name[fr_FR]=fix-clavier
Comment[fr_FR]=fix-clavier
Comment=fix-clavier
Exec=setxkbmap $LOCALSIMPLE
X-GNOME-Autostart-enabled=true" | tee /etc/xdg/autostart/fix-clavier.desktop &>/dev/null

## icone partage
#cp -f $UBUKEYDIR/launchers/gc.desktop /etc/skel/"$deskdir"
#chmod +x /etc/skel/"$deskdir"/gc.desktop

fi ## fin si console debootstrap


## suivant type session en prevision...
case $sessionType in
gnome)
gconftool-2 -t boolean -s /apps/nautilus/desktop/volumes_visible false
sudo -u "$USER" gconftool-2 --type bool --set /apps/gnome-screensaver/idle_activation_enabled false
sudo -u "$USER" gconftool-2 --type bool --set /apps/gnome-screensaver/lock_enabled false
;;
kde4)
message "Kde4 detecte... verification de zenity, kdm et de l utilisateur chroot\n"
if [ ! -e "/usr/bin/zenity" ]; then
message "Zenity manquant, installation\n"
apt-get -y --force-yes install zenity
else
message "zenity ok \n"
fi

## reconfigure autologin kdm-kde4...
if [ ! -e "/etc/kde4/kdm/kdmrc" ]; then
genkdmconf
fi
#~ sed -i "s/#AutoLoginUser=.*/AutoLoginUser=$chuser/" /etc/kde4/kdm/kdmrc
#~ sed -i 's/#AutoLoginEnable=.*/AutoLoginEnable=True/' /etc/kde4/kdm/kdmrc
;;
xfce4)

;;
esac

####################################### CASPER CHECK
if [ ! -e "/etc/casper.conf" ]; then
apt-get -y --force-yes install casper
fi

message "Reverifie l integritee du dossier /etc/skel (peut etre long...) \n"
chuser=$(cat /etc/casper.conf | grep -w "USERNAME=" | sed 's/.*=//' | sed 's/"//g')
if [[ "$USER" != "$chuser" ]]; then
LISTE="`find /etc/skel/ -type f | sed '/.thumbnails/d;/.cache/d;/.purple/d;/.icons/d;/.emerald/d;/.mozilla/d;/.dbus/d;/.themes/d;/.png/d;/.jpeg/d;/.jpg/d;/.bin/d;/find/d'`"
echo -e "$LISTE" | while read file; do 

if [[ -e "$file" && `cat "$file" | grep -e "$chuser"` ]]; then 
sed -i "s%=$chuser%=$USER%g;s%\/home\/$chuser%\/home\/$USER%g" "$file"
fi

done
fi

## verif compiz
if [ -e "/etc/skel/.config/compiz/fusion-icon" ]; then
echo -e "Remplace compiz par $decorator"
sed -i 's/wm = .*/wm = '"$decorator"' /' /etc/skel/.config/compiz/fusion-icon
fi

#if [ "$sessionType" != "console" ]; then
## verif lanceur partage du / (bug avec nautilus...)
#if [[ ! -e "/usr/bin/gnome-commander" || ! -e "/usr/share/pixmaps/share.png" ]]; then
#message "Installation de gnome-commander pour le partage des disques entre local et chroot \nVotre pc local sera monté sur /media/pc-local"
#apt-get -y --force-yes install gnome-commander &>/dev/null
#cp $UBUKEYDIR/images/share.png /usr/share/pixmaps/
#fi
#fi

############## STARTX #############################

cd /tmp
rm -R /tmp/.X11*
xauth generate :5 .

message "Tout est pret, demarre X dans le chroot ! \n"

message "starter = $starter"
chown -hR "$USER":"$USER" /etc/skel

echo '#!/bin/bash
export DISPLAY=:5
sudo -u '$USER' '$starter'
' | tee /usr/local/bin/startchroot &>/dev/null
chmod +x /usr/local/bin/startchroot

xterm -title "Close this window to exit your session" -display :5 -e startchroot

} ## fin chroot graphique

function CLEANCHROOT()
{
message "Sortie du chroot ok, Nettoyage\n"

## check kde4
## si autologin activé changes utilisateur en rapport avec /etc/casper.conf
if [ "$sessionType" = "kde4" ]; then

if [[ `cat "/etc/kde4/kdm/kdmrc" | grep -e "^AutoLoginEnable=true"` ]]; then
chuser=$(cat /etc/casper.conf | grep -w "USERNAME=" | sed 's/.*=//' | sed 's/"//g')
message "Modification de l utilisateur par defaut pour kdm-kde4 avec l utilisateur $chuser \n"
sed -i "s/AutoLoginUser=.*/AutoLoginUser=$chuser/" /etc/kde4/kdm/kdmrc
fi

## edite le fichier de config plasma pour virer icones quitter et assistant...
line=$(cat /etc/skel/.kde4/share/config/plasma-appletsrc | grep -B1 "quit-chroot")
echo -e "$line" | while read lines; do
sed -i '/[$lines]/d' /etc/skel/.kde4/share/config/plasma-appletsrc
done

line=$(cat /etc/skel/.kde4/share/config/plasma-appletsrc | grep -B1 "ubukey-assist")
echo -e "$line" | while read lines; do
sed -i '/[$lines]/d' /etc/skel/.kde4/share/config/plasma-appletsrc
done

fi ## fin si kde4

################
## nettoie user

message "Reverifie l integritee du dossier /etc/skel (peut etre long...) \n"
chuser=$(cat /etc/casper.conf | grep -w "USERNAME=" | sed 's/.*=//' | sed 's/"//g')
if [[ "$chuser" != "$USER" ]]; then
LISTE="`find /etc/skel -type f | sed '/.thumbnails/d;/.cache/d;/.purple/d;/.icons/d;/.emerald/d;/.mozilla/d;/.dbus/d;/.themes/d;/.png/d;/.jpeg/d;/.jpg/d;/.bin/d;/find/d'`"
echo -e "$LISTE" | while read file; do 
if [[ -e "$file" && `cat "$file" | grep -e "$USER"` ]]; then 
sed -i "s%=$USER%=$chuser%g;s%\/home\/$USER%\/home\/$chuser%g" "$file"
fi
done
fi

socketFiles=$(find /etc/skel -type s -o -type b -o -type p)
echo -e "$socketFiles"| while read file; do
type=$(file "$file" | cut -f2 -d' ')
echo -e "Efface le fichier socket: $file \n"
rm -f "$file"
done

## fix gconf
if [ -e "/etc/skel/.gconfd/saved_state" ]; then
rm /etc/skel/.gconfd/saved_state
fi

## remet user root
#sed -i 's/\/home\/.*:/\/root:/' chroot/etc/passwd
chown -R root:root /etc/skel
## maj kernel et/ou verification
message "Verifie l'integritee des fichiers vmlinuz/initrd \n"

kernel_count=$(ls -al /boot | grep initrd.img | wc | awk '{print $1}')

if [ $kernel_count > 2 ]; then
list=$(ls /boot | grep initrd.img | sed '$d')
echo -e "$list" | while read line; do
ver=$(echo -e $line | sed 's/.*initrd.img-//')
message "\nSuppression du kernel et headers version $ver \n"
apt-get remove -y --purge `dpkg -l | grep $ver | awk '{print $2}' | xargs`
done
fi

if [ ! -e "/usr/sbin/update-initramfs" ]; then
apt-get -y --force-yes install initramfs-tools
fi

## clean en cas de mise a jour du kernel important !!
if [ -e "/vmlinuz.old" ]; then
toRemove=$(ls -al /vmlinuz.old | sed 's/.*boot\/vmlinuz-//')
sleep 2

## nettoyage kernels multiples
removeHeaders=$( echo "$toRemove" |sed 's/-generic/*/')
##
message "Nettoyage des kernels superflus \n"
apt-get remove -y --force-yes linux-image-"$toRemove" linux-headers-"$toRemove"
rm -R /usr/src/linux-headers-"$toRemove" &>/dev/null
rm -R /lib/modules/"$toRemove" &>/dev/null
rm /*.bak
rm /*.old
rm /boot/*.bak
rm /boot/*.old
fi

## verification des kernels

## 1 liste le kernel le plus a jour installé
INIT=$(ls -al /boot | grep initrd.img | tail -n1 | sed 's/.*2.6/2.6/')
VMLINUZ=$(ls -al /boot | grep vmlinuz | tail -n1 | sed 's/.*2.6/2.6/')

## maj initiale au cas ou 
if [[ ! -e "/vmlinuz" || ! -e "/initrd.img" ]]; then
if [[ ! `ls /boot | grep vmlinuz` || ! `ls /boot | grep initrd.img` ]]; then
message "mise a jour des sources..."
apt-get update
message "\nReinstallation du kernel, patience svp...\n"
apt-get -y --force-yes install --reinstall linux-headers-generic linux-generic
else
INIT=$(ls /boot | grep initrd.img | tail -n1 | sed 's/.*2.6/2.6/')
VMLINUZ=$(ls /boot | grep vmlinuz | tail -n1 | sed 's/.*2.6/2.6/')
ln -s /boot/initrd.img-$INIT /initrd.img
ln -s /boot/vmlinuz-$VMLINUZ /vmlinuz
fi
fi

INIT=$(ls /boot | grep initrd.img | tail -n1 | sed 's/.*2.6/2.6/')
VMLINUZ=$(ls /boot | grep vmlinuz | tail -n1 | sed 's/.*2.6/2.6/')

## si le lien du kernel n'est pas le bon
INITLINK=$(ls -al /initrd.img | sed 's/.*2.6/2.6/')
VMLINUZLINK=$(ls -al /vmlinuz | sed 's/.*2.6/2.6/')
if [[ $INIT != $INITLINK || $VMLINUZ != $VMLINUZLINK ]]; then
rm /initrd.img
rm /vmlinuz
fi

message "Mise a jour des liens initrd.img et vmlinuz \n"
if [[ -e "/boot/vmlinuz-$INIT" && ! -e "/vmlinuz" || -e "/boot/initrd.img-$INIT" && ! -e "/initrd.img" ]]; then
ln -s /boot/vmlinuz-$INIT /vmlinuz
ln -s /boot/initrd.img-$INIT /initrd.img
fi

message "Nettoyage de dpkg \n"
dpkg -l |grep ^rc |awk '{print $2}' |xargs dpkg -P &>/dev/null
if [[ ! `egrep "ata-piix||all_generic_ide" /usr/share/initramfs-tools/modules` ]]; then
sed -i '/ata-generic/d;/ide-generic/d;/all_generic_ide/d' /usr/share/initramfs-tools/modules
echo -e "ata-generic\nide-generic\nall_generic_ide" | tee -a /usr/share/initramfs-tools/modules
fi

## debut nettoyage chroot
cd /tmp
if [ "$sessionType" = "gnome" ]; then
gconftool-2 -t boolean -s /apps/nautilus/desktop/volumes_visible true &>/dev/null
fi

## nettoyage apt
message "Nettoyage des paquets apt, gain de place sur le live... \n"
apt-get clean
dpkg -l |grep ^rc |awk '{print $2}' |xargs dpkg -P &>/dev/null
## remet a jour les sources....

## clean group and passwd files
deluser "$USER"
message "Verifie l integritee des fichiers passwd/groups et shadow \n"
sed -i '/^[^:]*:[^:]*:[1-9][0-9][0-9][0-9]:/d' /etc/passwd
sed -i '/^[^:]*:[^:]*:[12][0-9][0-9][0-9][0-9]:/d' /etc/passwd

sed -i '/^[^:]*:[^:]*:[1-9][0-9][0-9][0-9]:/d' /etc/group
sed -i '/^[^:]*:[^:]*:[12][0-9][0-9][0-9][0-9]:/d' /etc/group

sed -i '/^[^:]*:[^:]*:[^:]*:'$USER'/d' /etc/group
sed -i '/'$USER'/d' /etc/shadow- &>/dev/null
sed -i '/'$USER'/d' /etc/gshadow- &>/dev/null
sed -i '/'$USER'/d' /etc/gshadow &>/dev/null
sed -i '/'$USER'/d' /etc/shadow &>/dev/null
sed -i '/'$USER'/d' /etc/group &>/dev/null
sed -i '/'$USER'/d' /etc/passwd &>/dev/null

## recreate shadow/gshadow files and permissions
pwconv
grpconv
chown -R root:root /etc/skel/.

umount /etc/skel/.gvfs &>/dev/null
rm -rf /etc/skel/.gvfs &>/dev/null

#rm /sbin/initctl
#dpkg-divert --local --remove /sbin/initctl

message "nettoyage des fichiers de l utilisateur temporaire du chroot\n"
## efface utilisateur
rm /home/"$USER"/"$deskdir"/Shared_Folder
rm /etc/xdg/autostart/fix-clavier.desktop &>/dev/null
rm /etc/skel/.config/autostart/fix-clavier.desktop &>/dev/null
rm /etc/skel/.xsession-errors &>/dev/null
rm /etc/skel/.Xauthority &>/dev/null
rm -Rf /etc/skel/.gvfs &>/dev/null
rm /usr/local/bin/quit-chroot.sh &>/dev/null
rm /etc/skel/.ICEauthority &>/dev/null
rm -R /etc/skel/.gvfs &>/dev/null
rm -Rf /var/tmp/*  &>/dev/null 
rm -Rf /home/"$USER"  &>/dev/null

rm /etc/hosts  &>/dev/null
rm /etc/resolv.conf  &>/dev/null
rm /etc/X11/xorg.conf  &>/dev/null

## sortie du script et demonte tout
rm -R -f /var/crash/* &>/dev/null
rm -R -f /tmp/.* &>/dev/null
rm -R -f /root/* &>/dev/null
 
## more info for damn adduser under live-session
sed -i 's/user-setup-apply > \/dev\/null/user-setup-apply/' /usr/share/initramfs-tools/scripts/casper-bottom/10adduser &>/dev/null


}

message "Démarrage du chroot en mode $mode ! \n"
INITCHROOT
ln -sf /etc/skel/ /home/"$USER"
rm /etc/skel/skel
cd /home/"$USER"
export DISPLAY=localhost:5
#$UBUKEYDIR/scripts/ubusrc-gen
apt-get update
if [ ! -e "/usr/bin/xterm" ]; then
message "Installation de xterm \n"
apt-get install -y xterm
fi

CHROOTGRAPHIQUE
CLEANCHROOT

EOF

console=""
safe=""
mode=""
kill -9 `lsof -atw "${DISTDIR}"/chroot | xargs ` &>/dev/null

sleep 3
## remet bien le /root dans passwd...
#sed -i 's/\/home\/'$USER'/\/root/' "${DISTDIR}"/chroot/etc/passwd
mv "${DISTDIR}"/chroot/etc/mtab-save "${DISTDIR}"/chroot/etc/mtab
mv "${DISTDIR}"/chroot/etc/fstab-save "${DISTDIR}"/chroot/etc/fstab
rm "${DISTDIR}"/chroot/var/lib/dbus/machine-id &>/dev/null
rm -R "${DISTDIR}"/chroot/usr/share/ubukey &>/dev/null
if [[ !  `grep -w "\/root" "${DISTDIR}"/chroot/etc/passwd` ]]; then
echo -e "Probleme avec /etc/passwd..."
sleep 5
sed -i 's/\/home\/'$USER'/\/root/' "${DISTDIR}"/chroot/etc/passwd
fi


## nettoie et re verifie fichiers de conf
rm -f ${DISTDIR}/chroot/etc/skel/*/{ubukey-assist,quit-chroot,gc}.desktop  &>/dev/null
umount -l -f ${DISTDIR}/chroot/media/pc-local &>/dev/null
umount -l -f ${DISTDIR}/chroot/proc/sys/fs/binfmt_misc binfmt_misc  &>/dev/null
umount -l -f ${DISTDIR}/chroot/proc &>/dev/null
umount -l -f ${DISTDIR}/chroot/sys &>/dev/null
umount -l -f ${DISTDIR}/chroot/dev/pts &>/dev/null
umount -l -f ${DISTDIR}/chroot/dev &>/dev/null
umount -f "${DISTDIR}"/chroot/var/run/dbus &>/dev/null
rm "${DISTDIR}"/chroot/var/run/* &>/dev/null
umount -l -f ${DISTDIR}/chroot/media/pc-local/media &>/dev/null
umount -l -f ${DISTDIR}/chroot/media/pc-local/home &>/dev/null
umount /dev/loop* -l -f &>/dev/null
if [[ ! `mount | grep "pc-local"` ]]; then
	rm -R "${DISTDIR}"/chroot/media/pc-local &>/dev/null
fi
sed -i '/^>/d;/WARNING/d' "${DISTDIR}"/logs/chrootlog.log &>/dev/null

if [[ $(mount | grep "/proc/sys/fs/binfmt_misc") ]]; then
umount /proc/sys/fs/binfmt_misc &>/dev/null
kill -9 `lsof -atw "${DISTDIR}"/chroot | xargs` &>/dev/null
umount -l -f "${DISTDIR}"/chroot/proc &>/dev/null
umount -l -f "${DISTDIR}"/chroot/sys &>/dev/null
fi

echo -e "Verifie l integritee des fichiers passwd/groups et shadow \n"
sed -i '/^[^:]*:[^:]*:[1-9][0-9][0-9][0-9]:/d' "${DISTDIR}"/chroot/etc/passwd &>/dev/null
sed -i '/^[^:]*:[^:]*:[12][0-9][0-9][0-9][0-9]:/d' "${DISTDIR}"/chroot/etc/passwd &>/dev/null
sed -i '/^[^:]*:[^:]*:[1-9][0-9][0-9][0-9]:/d' "${DISTDIR}"/chroot/etc/group &>/dev/null
sed -i '/^[^:]*:[^:]*:[12][0-9][0-9][0-9][0-9]:/d' "${DISTDIR}"/chroot/etc/group &>/dev/null
sed -i '/^[^:]*:[^:]*:[^:]*:'$USER'/d' "${DISTDIR}"/chroot/etc/group &>/dev/null
sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/shadow- &>/dev/null
sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/gshadow- &>/dev/null
sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/gshadow &>/dev/null
sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/shadow &>/dev/null
sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/group &>/dev/null
sed -i '/'$USER'/d' "${DISTDIR}"/chroot/etc/passwd &>/dev/null


umount -f "${DISTDIR}"/chroot &>/dev/null
kill -9 `ps aux | grep chrootlog.log | awk '{print $2}' | xargs` &>/dev/null
echo "Sortie du chroot ok"

}

function testConnect() 
{
testconnexion=`wget www.google.fr -O /tmp/test &>/dev/null 2>&1`
if [ $? != 0 ]; then
sleep 5
echo  "Pause, vous êtes déconnecté !, en attente de reconnexion"
testConnect
fi
}

prepareChroot
