#!/bin/bash
###########

DESCRIPTION="Ce module permet d intégrer mon script compiz afin d installer celui-ci
en version Git et d'installer également avant window navigator et/ou cairo-dock
, screenlets ...
"

cd /usr/local/bin

if [[ "$UID" -ne 0 ]]; then
  	CMDLN_ARGS="$@"
	export CMDLN_ARGS
	exe=`pgrep compiz-smo.sh`
	exec sudo /usr/share/ubukey/addons/all/compiz-smo.sh && kill -9 "$exe" 
fi


echo -e "Récupère le script...\n"
sudo rm cfinstall.sh &>/dev/null
sudo wget -q http://phatandfresh.free.fr/cfinstall.sh
sudo chmod +x cfinstall.sh

echo -e "Modification de certaines parties pour adapter au fait d être en chroot\n"
sleep 2
#edit de certaines variables ou autre
user="$(cat /etc/lsb-release | grep CODENAME | sed 's/.*=//')"
sudo sed -i '/userChoice=/d' /usr/local/bin/cfinstall.sh
sudo sed -i 's/user=\"$userChoice\"/user=\"'$user'\"/' /usr/local/bin/cfinstall.sh
sudo sed -i 's/reboot -t now/exit 0/' /usr/local/bin/cfinstall.sh
sudo sed -i 's/nohup \/etc\/init.d\/gdm restart.*/exit 0/' /usr/local/bin/cfinstall.sh
sudo sed -i '/nohup \/etc/d' /usr/local/bin/cfinstall.sh
sudo sed -i '/Ok, Redemarrage du serveur X ou du pc ;))/d' /usr/local/bin/cfinstall.sh
sudo sed -i '/et tous les éléments du script/d' /usr/local/bin/cfinstall.sh
sudo sed -i '/FALSE "3D"/,/\\/d' /usr/local/bin/cfinstall.sh
sudo sed -i '/le pilote proprio/d' /usr/local/bin/cfinstall.sh
sudo sed -i 's/active wm = compiz/active wm = /g' /usr/local/bin/cfinstall.sh
sudo sed -i '/Voulez vous relancer votre session/,/relancer X\./d' /usr/local/bin/cfinstall.sh

echo -e "Démarre le script..."
sudo /bin/bash cfinstall.sh -y

sed -i 's/active wm = compiz/active wm = /g' "$HOME"/.config/compiz/fusion-icon

zenity --info --title "Fin de l'installation" \
--text "Opérations terminées, validez pour continuer."

kill -9 `ps aux | grep -e "hold" | grep -e [x]term | grep -e "/usr/share/ubukey/addons" | awk '{print $2}' | xargs`
