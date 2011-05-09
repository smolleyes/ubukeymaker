#!/bin/bash

WORK="$1"
CURDIST=`lsb_release -cs`

if [ -e "/usr/share/ubukey" ]; then 
UBUKEYDIR="/usr/share/ubukey"
elif [ -e "/usr/local/share/ubukey" ]; then
UBUKEYDIR="/usr/local/share/ubukey"
fi

function distName {
choix=`zenity --width=350 --height=80 --title "Nom du projet" --text "Indiquez un nom pour votre projet 

Un dossier du meme nom avec tous les éléments de votre live-cd sera ensuite crée
et servira d'environnement de travail.
" --entry `
	case $? in
		0)
			DIST="$(echo "$choix" | sed -e 's/ /_/g')"
			DISTDIR="${WORK}/distribs/$DIST"
			;;
		1)
			exit 1 ;; 
		*)
			exit 1 ;;
	esac
}

function testConnect() 
{
testconnexion=`wget www.google.fr -O /tmp/test &>/dev/null 2>&1`
if [ $? != 0 ]; then
sleep 5
echo  "Pause, vous êtes déconnecté !, annulez si vous n'avez pas de connexion internet... ou reconnectez vous"
testConnect
fi
}

function base_debootstrap()
{
#start the basic debootstrap
if [[ `mount | grep "$WORK" | grep -E '(ntfs|vfat|nosuid|noexec|nodev)'` ]]; then
	echo -e "Votre répertoire de travail ${WORK} est monté sur une partition avec une option de mount nosuid/noexec ou nodev incompatible avec debootstrap... merci de corriger votre fstab et remonter al partition avant de réessayer ! \n"
	sleep 3
	exit 0
fi

debootstrap --keep-debootstrap-dir --arch i386 $CURDIST "$DISTDIR"/chroot http://archive.ubuntu.com/ubuntu/

## send ubukey scripts
mkdir -p "${DISTDIR}"/chroot/usr/share/ubukey &>/dev/null
rsync -uravH --delete --exclude="*~,*.git" $UBUKEYDIR/. "${DISTDIR}"/chroot/usr/share/ubukey/.

## install xterm and some essentials packages for the script
echo -e "Installation de paquets essentiels au script \n"
cp /etc/resolv.conf "$DISTDIR"/chroot/etc
mkdir "$DISTDIR"/chroot/dev &>/dev/null
mount -o bind /dev "$DISTDIR"/chroot/dev

## start chroot
chroot "$DISTDIR"/chroot << EOF 
mount -t devpts none /dev/pts
mount -t proc none /proc
mount -t sysfs none /sys
apt-get update
apt-get -y install lsb-release xterm aptitude wget zenity

## generate new sources.list
chmod +x /usr/share/ubukey/scripts/ubusrc-gen
/bin/bash /usr/share/ubukey/scripts/ubusrc-gen

EOF

## start modules manager
. $UBUKEYDIR/scripts/debootstrap-packages.sh

## clean chroot
chroot "$DISTDIR"/chroot << EOF
umount /dev/pts
umount /proc
umount /sys
rm /etc/resolv.conf
EOF

umount -l -f "$DISTDIR"/chroot/dev &>/dev/null

}


function createEnv()
{
if [ ! -e "${DISTDIR}" ]; then
echo "Creation du dossier ${DISTDIR}"
mkdir "${DISTDIR}"

## creer fichier conf de chaque distrib
touch "${DISTDIR}"/config
echo "[$DIST]
distSession=console
Kernel=`uname -r`
debootstrap=true" | tee -a "${DISTDIR}"/config &>/dev/null
	echo -e "création du fichier de configuration... ok\n"
	chown "$USER" "${DISTDIR}"/config &>/dev/null
fi

cd "${DISTDIR}"

## creation des dossiers de base
echo "Création/vérification des dossiers de base pour $DIST"
dirlist="chroot temp save logs"
for i in $dirlist ; do
	if [ ! -e "$i" ]; then
		echo  "création du dossier $i"
		mkdir "${DISTDIR}"/"$i" &>/dev/null
	fi
done

## extract usb and cdrom templates
cd /tmp
rm *.tar.gz &>/dev/null
echo -e "\nTéléchargement du squelette pour dossier usb"
curl -C - -O http://www.penguincape.org/downloads/scripts/ubukey/deboot-skel/$CURDIST/usb.tar.gz
echo -e "\nTéléchargement du squelette pour dossier cdrom"
curl -C - -O http://www.penguincape.org/downloads/scripts/ubukey/deboot-skel/$CURDIST/cdrom.tar.gz

echo -e "\nExtraction et mise en place..."

mkdir "$DISTDIR"/cdrom
mkdir "$DISTDIR"/usb

tar xvf cdrom.tar.gz -C "${DISTDIR}"/cdrom &>/dev/null
tar xvf usb.tar.gz -C "${DISTDIR}"/usb &>/dev/null

}

distName
createEnv
base_debootstrap

echo -e "\nDebootstrap terminé ! \n"

