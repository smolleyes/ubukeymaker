#!/bin/bash

WORK=$1
USER=$2

if [ -e "/usr/share/ubukey" ]; then 
	UBUKEYDIR="/usr/share/ubukey"
elif [ -e "/usr/local/share/ubukey" ]; then
	UBUKEYDIR="/usr/local/share/ubukey"
else
	UBUKEYDIR="$(pwd)/.."
fi

function create_dist()
{

	## check ubukey link
	if [ ! -e "/usr/share/ubukey" ]; then
		ln -s "$(pwd)/.." /usr/share/ubukey
	fi

	## menu selection choix distrib a preparer 
	DISTCHOICE=`zenity --width=600 --height=500 --title "Choix Distribution a preparer" --list \
		--radiolist --column "Choix" --column "Action" --column "Description" \
		--text "Choisissez le type de distribution a utiliser

	<span color=\"red\">Information:</span>
	Si vous comptez utiliser un iso perso ou d'une autre distribution
	Choisissez son equivalence (gnome, kde, xfce etc...)
	" \
		FALSE "Ubuntu-Maverick" "Préparer pour ubuntu maverick" \
		FALSE "Ubuntu-Maverick-64" "Préparer pour ubuntu maverick 64 bits" \
		FALSE "Kubuntu-Maverick" "Préparer pour kubuntu maverick" \
		FALSE "Kubuntu-Maverick-64" "Préparer pour kubuntu maverick 64 bits" \
		FALSE "Xubuntu-Maverick" "Préparer pour xubuntu maverick" \
		FALSE "Xubuntu-Maverick-64" "Préparer pour xubuntu maverick 64 bits" \
		FALSE "Lubuntu-Maverick" "Préparer pour lubuntu maverick (lxde)" \
		FALSE "Ubuntu-lucid" "Préparer pour ubuntu lucid" \
		FALSE "Ubuntu-lucid-64" "Préparer pour ubuntu lucid 64 bits" \
		FALSE "Kubuntu-lucid" "Préparer pour kubuntu lucid" \
		FALSE "Kubuntu-lucid-64" "Préparer pour kubuntu lucid 64 bits" \
		FALSE "Xubuntu-lucid" "Préparer pour xubuntu lucid" \
		FALSE "Xubuntu-lucid-64" "Préparer pour xubuntu lucid 64 bits" \
		FALSE "Ubuntu-netbook-remix" "Préparer pour u.n.r lucid (pour mini-pc)" \
		FALSE "Lubuntu" "Préparer pour lubuntu lucid (lxde)" \
		FALSE "Oneiric" "Préparer pour ubuntu oneiric daily (gnome)" \
		FALSE "Precise-pangolin" "Ubuntu precise pangolin daily build" \
		FALSE "Custom" "Préparer vos distribution par debootstrap (Expert!)"
	`

	case $DISTCHOICE in
		Ubuntu-Maverick)
		ISOURL="http://releases.ubuntu.com/maverick/ubuntu-10.10-desktop-i386.iso"
		ISONAME="ubuntu-10.10-desktop-i386.iso"
		MD5SUM="59d15a16ce90c8ee97fa7c211b7673a8"
		ISOTYPE="gnome"
		;;
		Ubuntu-Maverick-64)
		ISOURL="http://releases.ubuntu.com/maverick/ubuntu-10.10-desktop-amd64.iso"
		ISONAME="ubuntu-10.10-desktop-amd64.iso"
		MD5SUM="1b9df87e588451d2ca4643a036020410"
		ISOTYPE="gnome"
		;;
		Kubuntu-Maverick)
		ISOURL="http://releases.ubuntu.com/kubuntu/10.10/kubuntu-10.10-desktop-i386.iso"
		ISONAME="kubuntu-10.10-desktop-i386.iso"
		MD5SUM="da50a1ddb22060a2abda6823c9d1148d"
		ISOTYPE="kde4"
		;;
		Kubuntu-Maverick-64)
		ISOURL="http://releases.ubuntu.com/kubuntu/10.10/kubuntu-10.10-desktop-amd64.iso"
		ISONAME="kubuntu-10.10-desktop-amd64.iso"
		MD5SUM="760c15562bdffba54f23852a5d47db4e"
		ISOTYPE="kde4"
		;;
		Xubuntu-Maverick)
		ISOURL="http://se.archive.ubuntu.com/mirror/cdimage.ubuntu.com/xubuntu/releases/10.10/release/xubuntu-10.10-desktop-i386.iso"
		ISONAME="xubuntu-10.10-desktop-i386.iso"
		MD5SUM="ea9ecc3486e8c2994d8779bbf5ad1b96"
		ISOTYPE="xfce4"
		;;
		Xubuntu-Maverick-64)
		ISOURL="http://se.archive.ubuntu.com/mirror/cdimage.ubuntu.com/xubuntu/releases/10.10/release/xubuntu-10.10-desktop-amd64.iso"
		ISONAME="xubuntu-10.10-desktop-amd64.iso"
		MD5SUM="c1747b3760ae9886f679facb28fd0e98"
		ISOTYPE="xfce4"
		;;
		Lubuntu-Maverick)
		ISOURL="http://people.ubuntu.com/~gilir/lubuntu-10.10.iso"
		ISONAME="lubuntu-10.10.iso"
		MD5SUM="098254aeb0153b10bcfce948c43a0df6"
		ISOTYPE="lxde"
		;;
		
		Ubuntu-lucid)
		ISOURL="http://mirror.ovh.net/ubuntu-releases/lucid/ubuntu-10.04-desktop-i386.iso"
		ISONAME="ubuntu-10.04-desktop-i386.iso"
		MD5SUM="d044a2a0c8103fc3e5b7e18b0f7de1c8"
		ISOTYPE="gnome"
		;;
		
		Ubuntu-lucid-64)
		ISOURL="http://mirror.ovh.net/ubuntu-releases/lucid/ubuntu-10.04-desktop-amd64.iso"
		ISONAME="ubuntu-10.04-desktop-amd64.iso"
		MD5SUM="3e0f72becd63cad79bf784ac2b34b448"
		ISOTYPE="gnome"
		;;

		Kubuntu-lucid)
		ISOURL="http://mirror.ovh.net/ubuntu-releases/kubuntu/10.04/kubuntu-10.04-desktop-i386.iso"
		ISONAME="kubuntu-10.04-desktop-i386.iso"
		MD5SUM="0ef722fd6b348e9dcf03812d071d68ba"
		ISOTYPE="kde4"
		;;
		
		Kubuntu-lucid-64)
		ISOURL="http://mirror.ovh.net/ubuntu-releases/kubuntu/10.04/kubuntu-10.04-desktop-amd64.iso"
		ISONAME="kubuntu-10.04-desktop-amd64.iso"
		MD5SUM="5b256bf515ae49749ac03a1af9d407c0"
		ISOTYPE="kde4"
		;;
		
		Xubuntu-lucid)
		ISOURL="http://cdimage.ubuntu.com/xubuntu/releases/10.04/release/xubuntu-10.04-desktop-i386.iso"
		ISONAME="xubuntu-10.04-desktop-i386.iso"
		MD5SUM="7f064bc012025a5307ef6d81b0bc4c87"
		ISOTYPE="xfce4"
		;;
		
		Xubuntu-lucid-64)
		ISOURL="http://cdimage.ubuntu.com/xubuntu/releases/10.04/release/xubuntu-10.04-desktop-amd64.iso"
		ISONAME="xubuntu-10.04-desktop-amd64.iso"
		MD5SUM="49d29d11c3eb51f862641a934c86dd79"
		ISOTYPE="xfce4"
		;;
		
		Ubuntu-netbook-remix)
		ISOURL="http://mirror.ovh.net/ubuntu-releases/lucid/ubuntu-10.04-netbook-i386.iso"
		ISONAME="ubuntu-10.04-netbook-i386.iso"
		MD5SUM="712277c7868ab374c4d3c73cff1d95cb"
		ISOTYPE="gnome"
		;;
		
		Lubuntu)
		ISOURL="http://people.ubuntu.com/%7Egilir/lubuntu-10.04.iso"
		ISONAME="lubuntu-10.04.iso"
		MD5SUM="386a227968cbabc89e1a23b95035160e"
		ISOTYPE="lxde"
		;;
		Oneiric-daily)
		ISOURL="http://cdimage.ubuntu.com/daily-live/current/oneiric-desktop-i386.iso"
		ISONAME="oneiric-desktop-i386.iso"
		cd /tmp
		rm MD5* >/dev/null
		wget http://cdimage.ubuntu.com/daily-live/current/MD5SUMS
		MD5SUM=$(cat MD5SUMS | grep desktop-i386 | awk '{print $1}')
		ISOTYPE="gnome"
		;;
		Precise-pangolin)
		ISOURL="http://cdimage.ubuntu.com/daily-live/current/precise-desktop-i386.iso"
		ISONAME="precise-desktop-i386.iso"
		cd /tmp
		rm MD5* >/dev/null
		wget http://cdimage.ubuntu.com/daily-live/current/MD5SUMS
		MD5SUM=$(cat MD5SUMS | grep desktop-i386 | awk '{print $1}')
		ISOTYPE="gnome"
		;;
		Custom)
		/bin/bash $UBUKEYDIR/scripts/debootstrap_dist.sh "$WORK"
		exit 1
		;;
		
		*) 
		END
		exit 1
		;;
		
	esac ## fin choix dist

	## defini repertoire de travail et lance creation environnement
	distName
	createEnv

}


function distName {
	choix=`zenity --width=350 --height=80 --title "Nom du projet" --text "Indiquez un nom pour votre projet 

	Un dossier du meme nom avec tous les éléments de votre live-cd sera ensuite crée
	et servira d'environnement de travail.
	" --entry `
	case $? in
		0)
		DIST="$(echo "$choix" | sed -e 's/ /_/g')"
		DISTDIR="${WORK}/distribs/$DIST" ;;
		1)
		exit 1 ;; 
		*)
		exit 1 ;;
	esac
}


##########################################################
## check de l environnement de base : image pour le chroot, dossiers de base cdrom usb etc
function createEnv()
{
	if [ ! -e "${DISTDIR}" ]; then
		echo "Creation du dossier ${DISTDIR}"
		mkdir "${DISTDIR}"

		## creer fichier conf de chaque distrib
		touch "${DISTDIR}"/config
		echo "[$DIST]
		distSession=$ISOTYPE
		Kernel=`uname -r`
		debootstrap=false" | tee -a "${DISTDIR}"/config &>/dev/null
		echo -e "création du dossier de configuration... ok\n"
		chown "$USER" "${DISTDIR}"/config &>/dev/null
	fi

	cd "${DISTDIR}"

	## creation des dossiers de base
	echo "Création/vérification des dossiers de base pour $DIST"
	dirlist="usb old cdrom chroot temp save logs"
	for i in $dirlist ; do
		if [ ! -e "$i" ]; then
			echo  "création du dossier $i"
			mkdir "${DISTDIR}"/"$i" &>/dev/null
		fi
	done

	## dialog iso
	getCd

	## mount du cd de base
	echo -e "Tout est prêt, mount du cdrom $ISONAME \n" 
	sleep 3
	mount "$ISO" "${DISTDIR}"/old -o loop

	## copies dans dossier cdrom / nettoie
	SOURCE="${DISTDIR}/old"
	DESTINATION="${DISTDIR}/cdrom"
	TAILLE=$(($(du -sB 1 ${SOURCE} --exclude="filesystem.squashfs" | awk '{print $1}')/1000/1000))
	echo -e "Copie le contenu de base du fichier iso (sans le squashfs) dans le dossier cdrom, Taille: $TAILLE Mb \n"
	sleep 3
	rsync -aH --exclude="filesystem.squashfs" "${SOURCE}"/. "${DESTINATION}"/. &>/dev/null

	echo -e "Copie de la base du cdrom... ok \n"
	rm -rf "${DISTDIR}"/cdrom/programs
	chmod 755 -R "${DISTDIR}"/cdrom

	## si pas de copie direct demandee 
	if [ -z "$DIRECT_COPY" ]; then

		## copie dans le chroot / demonte squashfs
		echo  -e "Copie du squashfs... \n"
		unsquashfs -i -d "${DISTDIR}"/chroot -f "${SOURCE}"/casper/filesystem.squashfs

		echo -e "Copie du squashfs terminée... ok \n"
		## demonte live-cd de base
		umount "${DISTDIR}"/old &>/dev/null
	fi

	SOURCE=""
	DESTINATION=""

	## copies le necessaire dans dossier usb  
	echo -e "Prépare dossier usb...\n"
	sleep 3
	cp -R "${DISTDIR}"/cdrom/. "${DISTDIR}"/usb/.

	rm -Rf "${DISTDIR}"/usb/isolinux
	mv "${DISTDIR}"/usb/casper/initrd.* "${DISTDIR}"/usb/ &>/dev/null
	mv "${DISTDIR}"/usb/casper/vmlinuz "${DISTDIR}"/usb/

	if [ -z "$DIRECT_COPY" ]; then

		echo -e "La préparation de l'environnement pour la distrib $DIST est terminée,
		Les fichiers se trouvent dans :
		${DISTDIR} \n
		"
		sleep 5
	else
		echo -e "Preparation du dossier temporaire avant copie sur cle ok ! \n"
	fi

}


function getCd()
{
	## download le cd de base
	GETCD=$(zenity --width=500 --height=200 --title "Selection fichier image" --list --text "Choisissez votre option" --radiolist --column "Choix" --column "Action" --column "Description"  \
		TRUE "Select" "Indiquer ou se trouve le fichier iso" \
		FALSE "Download" "Télécharger l'iso de la distrib séléctionnée" )
	case $GETCD in
		Select) SELECTED="`zenity --file-selection --filename=/home/$USER/ --title "Choisissez un fichier iso"`"
		case $? in 
			0)
			echo 
			echo -e "Fichier séléctionné: "$SELECTED" \n"
			ISO="$SELECTED"
			ISONAME="`basename "$SELECTED"`"
			;;
			1) getCd
			;;
		esac
		;;## fin Selected
		Download) 
		download="$ISOURL"
		## down du resultat
		echo  "Download du cd de base "$download""
		sleep 3
		cd "${WORK}"/isos
		test -e "$ISONAME" && rm "$ISONAME"
		testConnect
		wget -c -nd $download 2>&1 | sed -u 's/\([ 0-9]\+K\)[ \.]*\([0-9]\+%\) \(.*\)/\2\n#Transfert : \1 (\2) à \3/' | zenity --progress  --auto-close  --width 400  --title="Téléchargement de l'iso" --text="Téléchargement de l'image "$ISONAME" en cours..."
		ISO=""${WORK}"/isos/"$ISONAME""
		## copie cd en sauvegarde si besoin
		
		;;## fin Download
		*) exit 1
		;;
	esac

	## verifie le md5sum
	echo -e "Vérification du md5sum... \n"
	if [ $ISONAME == "natty-desktop-i386.iso" ]; then
		cd /tmp
		rm MD5SUMS &>/dev/null
		wget http://cdimage.ubuntu.com/daily-live/current/MD5SUMS &>/dev/null
		MD5SUM=$(cat MD5SUMS | grep i386.iso | awk '{print $1}')
	fi
	DOWNSUM="`md5sum "$ISO" | awk {'print $NR'} `"

	if [[ "$DOWNSUM" != "$MD5SUM" ]]; then
		zenity --error --text "Iso corrompu, le md5sum ne correspond pas !

		Md5sum original : $MD5SUM
		Votre iso : $DOWNSUM 

		Continuez pour choisir ce que vous voulez faire :)
		"

		zenity --question --text "Choix de l'action à effectuer

		Cliquez sur \"Valider\" pour continuer de force :

		Par exemple si vous utilisez un iso que vous avez
		crée precedemment ou téléchargé ailleur...
		Que vous avez déjà testé et que tout est fonctionnel.

		Si par contre, si vous venez de le télécharger l'iso par ce script
		alors cliquez \"annuler\" pour revenir au menu principal"

		case $? in
			0)
			echo -e "Ok, on continue avec votre fichier iso...\n"
			;;
			1)
			echo -e ""
			choose_action
			;;
		esac
		
	else
		echo -e "Md5sum original : $MD5SUM"
		echo -e "Md5sum fichier iso : $DOWNSUM  \n"
		echo -e "Votre fichier iso est valide, Md5sum ok ! \n"
	fi

}

## ptite fonction pour zenity a cause de dd pas de verbose...
function makeProgress() {
	until [[ ! `ps aux | grep -e "$1"` ]]; do
		echo "ok"
		sleep 1
	done
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


create_dist
