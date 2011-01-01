function install_packages()
{
session=$1
echo -e "Installation des paquets pour $session \n"
lang=$(env | grep -w "LANG" | sed -e 's/\..*//;s/LANG=//;s/_.*//')
. /usr/share/ubukey/deboot-modules/$session
chroot "$DISTDIR"/chroot aptitude -y install --without-recommends `echo -e "$packages" | sed -e '/^#/d' | xargs`

## extra-packages (install with recommends)
if [ $session = "gnome" ]; then
	chroot "$DISTDIR"/chroot aptitude -y install indicator-session indicator-applet-session gnome-media alacarte network-manager gvfs-backends gvfs-bin gvfs-fuse plymouth plymouth-theme-ubuntu-logo plymouth-theme-ubuntu-text 
	chroot "$DISTDIR"/chroot apt-get remove -y --force-yes gwibber ubuntuone*
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
	install_packages gnome
	;;
	kde4)
	install_packages kde4
	;;
	lxde)
	install_packages lxde
	;;
	xfce4)
	install_packages xfce4
	;;
	*)
	exit 0
	;;
esac

