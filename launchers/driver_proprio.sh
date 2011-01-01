#!/bin/bash

DESCRIPTION="Installation des drivers propriétaires ATI .run officiel du site et NVIDIA version envy"

INIT=$(ls -al "/initrd.img" | sed 's/.*.img-//')
DIST_VERSION="$(lsb_release -cs)"

cd /usr/local/bin
rm ubusrc-gen &>/dev/null
wget http://www.ubukey.fr/files/ubusrc-gen &>/dev/null
chmod +x ubusrc-gen
ubusrc-gen

function PREPARE()
{

## ajoute depot envy
sed -i '/envyng-hardy/d' /etc/apt/sources.list
echo -e "deb http://ppa.launchpad.net/envyng-hardy/ubuntu ${DIST_VERSION} main" | tee -a /etc/apt/sources.list
apt-get update &>/dev/null

echo ""
echo -e "Nettoyage de tout driver deja installé \n"
#supprimer tous driver proprio
apt-get remove --purge -y `dpkg -l | grep -e "nvidia" | awk '{print $2}'| xargs`
apt-get remove --purge -y `dpkg -l | grep -e "fglrx" | awk '{print $2}'| xargs`
apt-get clean
echo -e "ok\n"

#install dependances
INSTALLER="linux-backports-modules-${INIT} linux-headers-generic linux-image-generic linux-restricted-modules-${INIT} build-essential dkms debhelper dpatch gettext html2text intltool-debian po-debconf nvidia-kernel-common"
aptitude -y install $INSTALLER

}

#telecharger paquets proprio dans /opt/reserve
function DL_PROPRIO()
{

if [ $DIST_VERSION = "intrepid" ]; then
LISTE="nvidia-settings nvidia-glx-177 nvidia-177-kernel-source nvidia-177-modaliases nvidia-glx-173 nvidia-173-kernel-source nvidia-173-modaliases xorg-driver-fglrx fglrx-kernel-source fglrx-amdcccle fglrx-modaliases"
else
LISTE="nvidia-settings nvidia-glx${CHOIX_PROPRIO} nvidia-glx-legacy${CHOIX_PROPRIO} nvidia-glx-new${CHOIX_PROPRIO} nvidia-new-kernel-source-envy nvidia-legacy-kernel-source-envy"
fi

mkdir /opt/reserve &>/dev/null
cd /opt/reserve
rm -R /opt/reserve/* &>/dev/null
echo -e "Telechargement des paquets deb, ils seront enregistre dans /opt/reserve \n"
sleep 3
LISTE=$(echo -e "$LISTE" | grep -v "^#" | xargs)
for prog in ${LISTE}; do
ADRESSE=$(sudo apt-get install -d -y -qq --reinstall --print-uris "^${prog}$" | grep ${prog} | awk '{print $1}')
echo -e "wget ${ADRESSE} -O ${prog}.deb" | tee -a telecharger
done
. ./telecharger

################################################### ATI .run du site
DIST=$(grep "CODENAME" /etc/lsb-release | sed 's/.*=//')

echo "Preparation pour le driver ATI fglrx"

if [[ $DIST_VERSION = "hardy" || $DIST_VERSION = "intrepid" ]];then
	if [ ! -e "/usr/bin/gatos-conf" ]; then
		aptitude -y install gatos &>/dev/null
	fi
	ln -s /usr/bin/scanpci.gatos /usr/bin/scanpci  &>/dev/null
	mkdir /usr/X11R6/lib/modules &>/dev/null
	mkdir /usr/X11R6/lib/modules/dri &>/dev/null
	ln -s /usr/X11R6/lib/modules/dri/fglrx_dri.so /usr/lib/dri/fglrx_dri.so &>/dev/null

else ## a enlever quand ati .run marchera sur intrepid

VIDEO_CARDS=`lspci | grep VGA`
ATI=`echo ${VIDEO_CARDS} | grep "ATI Technologies"`
ATIUNKNOW=`echo ${VIDEO_CARDS} | grep -e "ATI Technologies Inc Unknown device * "`

################
# Preparation  #
################
cd /tmp
wget -q http://ubuntu.rabbattskeudz.com/atilegacy
wget -q http://ubuntu.rabbattskeudz.com/atinew
rm /tmp/scanpci &>/dev/null
scanpci >>/tmp/scanpci

card=(`sed -n '/ATI/{g;1!p;};h' /tmp/scanpci |  awk {'print $NF'} | sed 's/0x//'`) 2>/dev/null

if egrep "$card" /tmp/atinew &>/dev/null ; then 
atilink="https://a248.e.akamai.net/f/674/9206/0/www2.ati.com/drivers/linux/ati-driver-installer-8-8-x86.x86_64.run"
atidriver="ati-driver-installer-8-8-x86.x86_64.run"
elif egrep "$card" /tmp/atilegacy &>/dev/null  ; then
atilink="https://a248.e.akamai.net/f/674/9206/0/www2.ati.com/drivers/linux/ati-driver-installer-8.28.8.run"
atidriver="ati-driver-installer-8.28.8.run"
else
atilink="https://a248.e.akamai.net/f/674/9206/0/www2.ati.com/drivers/linux/ati-driver-installer-8-8-x86.x86_64.run"
atidriver="ati-driver-installer-8-8-x86.x86_64.run"
fi

###########################
# Detection du type de distrib dapper/edgy/feisty possibilitee debian ou autre pour compilation fglrx.....
###########################
case $DIST_VERSION in
	gutsy  )
		ATI_DIST="Ubuntu/gutsy" ;;
    feisty )
        ATI_DIST="Ubuntu/feisty";;
    edgy)
        ATI_DIST="Ubuntu/edgy"  ;;
    dapper)
        ATI_DIST="Ubuntu/dapper";;
	hardy) 
		ATI_DIST="Ubuntu/hardy" ;;
esac
############################
echo "Detection et nettoyage des installations precedentes de paquets deb et binaire ati .run..."
sleep 2
## nettoie paquets deb
aptitude purge -y fglrx-control fglrx-kernel-`uname -r` fglrx-kernel-source xorg-driver-fglrx xorg-driver-fglrx-envy xorg-driver-fglrx-dev fglrx-amdcccle &>/dev/null
rm /usr/src/fglrx*.deb &>/dev/null
rm -R /usr/src/modules/fglrx* &>/dev/null

echo "Nettoyage effectue"
sleep 3		
echo "Mise a jour des depots et Telechargement des paquets necessaires...."
sleep 2
apt-get update &>/dev/null
aptitude -y install fakeroot cdbs dh-make debconf libstdc++5 linux-headers-$(uname -r) dkms gawk &>/dev/null

echo "Telechargement du binaire ati...."
sleep 2
cd /opt/reserve
wget --progress=dot --no-check-certificate $atilink

echo "Creation des paquets...."
sleep 2
chmod +x $atidriver
bash $atidriver --buildpkg $ATI_DIST
rm *.run*
############ fin ati .run

fi
}

function CONFIG()
{
#creer le script init du liveusb
echo -e "Telecharge le script d init des drivers proprio... \n"
cd /etc/init.d
rm activer-driver-proprio &>/dev/null
wget -q http://www.ubukey.fr/files/launchers/activer-driver-proprio

chmod +x "/etc/init.d/activer-driver-proprio"

sed -i "s/ casper-reconfigure \/root xserver-xorg/ #casper-reconfigure \/root xserver-xorg/g" \
	/usr/share/initramfs-tools/scripts/casper-bottom/20xconfig
	
echo -e "Activation des liens Rc (boot)"
update-rc.d activer-driver-proprio defaults &>/dev/null
echo -e "OK \n"

}

CHOIX_DRIVER=$(zenity \
--title="Live CD/USB" \
--text="Choisir l\'option désirée dans la liste ci-dessous

Les drivers seront téléchargés, puis installé en direct a chaque boot du live-cd
selon la carte détectée..." \
--window-icon="/usr/share/pixmaps/gnome-debian.png" \
--width=600 \
--height=300 \
--list \
--print-column="2" \
--radiolist \
--separator=" " \
--column="*" \
--column="Val" \
--column="Fonction à exécuter" \
--hide-column="2" \
FALSE "A" "Désinstaller les driver propriétaire" \
TRUE "B" "Installer les derniers drivers propriétaire ATI & NVIDIA Ubuntu version Envy")

if [ "$?" != "0" ]; then # Bouton Annuler
echo -e "Annulation"
CHOIX_PROPRIO=""

elif [ "${CHOIX_DRIVER}" == "A" ]; then
	echo -e "Désinstaller les driver propriétaire"
	CHOIX_PROPRIO=""
	PREPARE
	rm -R /opt/reserve/*
	update-rc.d -f activer-driver-proprio remove
	sed -i "s/#casper-reconfigure \/root xserver-xorg/casper-reconfigure \/root xserver-xorg/g" \
	/usr/share/initramfs-tools/scripts/casper-bottom/20xconfig
	rm /etc/init.d/activer-driver-proprio

elif [ "${CHOIX_DRIVER}" == "B" ]; then
	echo -e "Installer les drivers propriétaire ATI & NVIDIA Ubuntu Envy (versions plus récentes)"
	CHOIX_PROPRIO='-envy'
	PREPARE
	DL_PROPRIO
	CONFIG
	
	## compile module radeonhd en plus :)
	if [ ! -e "/usr/lib/xorg/modules/drivers/radeonhd_drv.so" ]; then
	apt-get update
	message "Le Driver Radeon HD est inexistant, celui ci va etre compilé... \n"
	message "Installation des dependences pour le pilote radeon HD version git \n"
	aptitude -y install git-core configure-debian automake autoconf xorg-dev libtool libdrm-dev build-essential xserver-xorg-dev xutils-dev
	cd /tmp
	message "Téléchargement des sources Git \n"
	git-clone git://anongit.freedesktop.org/git/xorg/driver/xf86-video-radeonhd
	message "Compilation \n"
	cd xf86-video-radeonhd/
	./autogen.sh --prefix=/usr/
	make
	make install
	else
		echo -e "Pilote RadeonHd déja installe...\n"
	fi
fi

echo -e "Configuration des drivers proprio terminée \n"

if [ ! -e "/etc/ubukey/distname" ]; then
	zenity --warning --text "Pour eviter de gros problèmes d'affichage apres installation
	sur disque dur...

	Pensez à executer le module \"install-hdd.sh\" présent 
	dans le gestionnaire de modules de l assistant de customisation 
	(ou commande ubukey-addons_manager.sh) \!"
fi

zenity --info --title "Fin de l installation" \
--text "Opérations terminées, validez pour continuer."

kill -9 $(ps aux | grep -e "root" | grep -e [x]term | grep -e "/usr/local/bin/ubukey-addons" | awk '{print $2}' | xargs)
exit 0
