if [ -e "/usr/share/ubukey" ]; then 
UBUKEYDIR="/usr/share/ubukey"
elif [ -e "/usr/local/share/ubukey" ]; then
UBUKEYDIR="/usr/local/share/ubukey"
else
UBUKEYDIR="$(pwd)/.."
fi


DIST=`lsb_release -cs`
rm /tmp/pack &>/dev/null

function install_packages()
{
session=$1
echo -e "Installation des paquets pour $session \n"
lang=$(env | grep -w "LANG" | sed -e 's/\..*//;s/LANG=//;s/_.*//')
. $UBUKEYDIR/deboot-modules/$session

packageList="$(echo "$packages" | sed -e '/^#/d;s/\"//g' | xargs)"
echo "checking packages availability..."
for p in $packageList ;do 
	if [[ `apt-cache search $p | grep $p` ]]; then 
		echo "package $p installable"
		echo "$p" | tee -a /tmp/pack &>/dev/null
	else 
		echo "The package $p is not available for installation..."
	fi
done
chroot "$DISTDIR"/chroot apt-get -y --force-yes install --no-install-recommends `cat /tmp/pack | xargs`

## extra-packages (install with recommends)
if [ $session = "gnome" ]; then
	chroot "$DISTDIR"/chroot apt-get -y --force-yes install indicator-session gnome-media alacarte network-manager gvfs-backends gvfs-bin gvfs-fuse plymouth plymouth-theme-ubuntu-logo plymouth-theme-ubuntu-text
	chroot "$DISTDIR"/chroot apt-get remove -y gwibber ubuntuone*
fi 
##

if [ "$session" != "" ]; then
	sed -i "s/distSession=.*/distSession=$session/" "$DISTDIR"/config
fi
}

## menu choix packages
ACTION=`zenity --width 500 --height 400 --title "selecteur de modules" --list --text "Sélectionner les modules à installer

note: 
Ces modules installent le minimum possible pour chaque session
avec le serveur x, un kernel et quelques paquets essentiels...(lubuntu = lxde)
" --radiolist --column "Choix" --column "Action"  \
TRUE "gnome" \
FALSE "kde4" \
FALSE "xfce4" \
FALSE "lxde"`

case $ACTION in
	gnome)
	install_packages gnome | tee /tmp/debootlog
	;;
	kde4)
	install_packages kde4 | tee /tmp/debootlog
	;;
	lxde)
	install_packages lxde | tee /tmp/debootlog
	;;
	xfce4)
	install_packages xfce4 | tee /tmp/debootlog
	;;
	*)
	exit 0
	;;
esac

zenity --question \
--title "Paquets supplémentaires" \
--text "Voulez vous installer des paquets supplémentaires (RECOMMANDE) ?" 
if [ "$?" != 1 ]; then
    . $UBUKEYDIR/scripts/debootstrap_packages_chooser.sh
fi

