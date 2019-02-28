echo 'If you have not tested if sudo is working for your user account, please press [Ctrl+C] now, otherwise press [Enter] to disable the Root account and continue'
read SUDO
case "$SUDO" in
	*);;
esac

sudo passwd -l root

mkdir ~/builds && mkdir ~/builds/aur

echo 'Please select your GPU vendor'
select GRAPHICS in 'AMD' 'ATI' 'Intel' 'NVIDIA'
do
	case $GRAPHICS in
		'AMD'|'ATI'|'Intel'|'NVIDIA')
			break
			;;
		*)
			echo 'Please select your GPU vendor'
			;;
	esac
done

echo 'Please select a desktop environment'
select DESKTOP in "GNOME 3" "KDE Plasma 5" "MATE"
do
	case $DESKTOP in
		"GNOME 3"|"KDE Plasma 5"|"MATE")
			break
			;;
		*)
			echo 'Please select one of the available desktops'
			;;
	esac
done

echo 'Please select a display server'
select DSERVER in 'Xorg' 'Xorg & Wayland'
do
	case $DSERVER in
		'Xorg'|'Xorg & Wayland')
			break
			;;
		*)
			echo 'Please select a display server'
			;;
	esac
done

if [[ $DESKTOP = "GNOME 3" ]]; then
    DE=$'gnome gnome-tweaks seahorse'
    echo 'inode/directory=org.gnome.Nautilus.desktop' >> ~/.config/mimeapp.list
fi

if [[ $DESKTOP = "KDE Plasma 5" ]]; then
    DE=$'plasma ark dolphin falkon kcalc kcharselect kfind kgpg khelpcenter kwrite okular spectacle'
fi

if [[ $DESKTOP = "MATE" ]]; then
    DE=$'mate mate-menu mate-applet-dock mozo pluma eom atril engrampa caja-wallpaper caja-open-terminal mate-calc mate-screensaver mate-media blueman network-manager-applet mote-power-manager plank lightdm lightdm-gtk-greeter seahorse firefox'
fi

if [[ $DSERVER = 'Xorg' ]]; then
	DSERV=$'xorg xorg-server'
fi

if [[ $DSERVER = 'Xorg & Wayland' ]]; then
	DSERV=$'xorg xorg-server xorg-server-wayland wayland'
fi

if [[ $DSERVER = 'Xorg & Wayland' ]] && [[ $DESKTOP = 'KDE Plasma 5' ]]; then
	DSERV=$'xorg xorg-server xorg-server-wayland wayland plasma-wayland-session'
fi

if [[ $GRAPHICS = 'AMD' ]]; then
	GPU=$'xf86-video-amdgpu'
fi

if [[ $GRAPHICS = 'ATI' ]]; then
	GPU=$'xf86-video-ati'
fi

if [[ $GRAPHICS = 'Intel' ]]; then
	GPU=$'xf86-video-intel'
fi

if [[ $GRAPHICS = 'NVIDIA' ]]; then
	GPU=$'xf86-video-nouveau'
fi

sudo pacman -Syu $DSERV $GPU mesa $DE tilix zsh veracrypt k3b gparted neofetch flatpak

if [[ $DESKTOP = "GNOME 3" ]]; then
    sudo systemctl enable gdm
fi

if [[ $DESKTOP = "KDE Plasma 5" ]]; then
    sudo systemctl enable sddm
fi

if [[ $DESKTOP = "MATE" ]]; then
    sudo systemctl enable lightdm
fi

if [ -e ./step-4.sh ]; then
	rm ./step-4.sh
fi

reboot