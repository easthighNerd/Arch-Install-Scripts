for FLAG in "$@"
do
case $FLAG in
	--LVMLUKS)
	LVMLUKS="Yes"
	;;
esac
done

echo 'Please restate the disk you partitioned (in lowercase) (i.e. sda)'
read SDX
case "$SDX" in
	*);;
esac

echo 'Please reselect your partition setup'
select PARTITION in 'BIOS' 'UEFI' 'LVM on LUKS with BIOS' 'LVM on LUKS with EFI'
do
	case $PARTITION in
		'BIOS'|'UEFI'|'LVM on LUKS with BIOS'|'LVM on LUKS with EFI')
			break
			;;
		*)
			echo 'Please select the partition layout that you setup in the previous step'
			;;
	esac
done

if [[ $PARTITION = 'LVM on LUKS BIOS' ]] || [[ $PARTITION = 'LVM on LUKS EFI' ]]; then
	LVMLUKS="Yes"
fi

if [[ $LVMLUKS = 'Yes' ]]; then
	mkdir /run/lvm && mount --bind /hostrun/lvm /run/lvm
fi

ln -sf /usr/share/zoneinfo/America/New_York /etc/localetime

hwclock --systohc

nano /etc/locale.gen && locale-gen

echo 'LANG=en_US.UTF-8' >> /etc/locale.conf

echo 'Please name the machine'
read MACHINENAME
case $MACHINENAME in
	*);;
esac

echo "$MACHINENAME" >> /etc/hostname

echo "127.0.0.1   localhost" >> /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   $MACHINENAME.localdomain $MACHINENAME" >> /etc/hosts

if [[ $LVMLUKS = 'Yes' ]]; then
	echo 'Add the `keyboard`, `encrypt` and `lvm2` hooks to HOOKS=(base udev autodetect' && sleep 5

	nano /etc/mkinitcpio.conf && mkinitcpio -p linux
fi

passwd

if [[ $PARTITION = 'BIOS' ]]; then
	grub-install --target=1386-pc /dev/sdx
fi

if [[ $PARTITION = 'LVM on LUKS with BIOS' ]]; then
	grub-install --target=1386-pc --boot-directory=/boot /dev/sdx
fi

if [[ $PARTITION = 'UEFI' ]] || [[ $PARTITION = 'LVM on LUKS with EFI' ]]; then
	grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --removable
fi

if [[ $LVMLUKS = 'Yes' ]]; then
	echo 'Take a picture or write down of the UUID below before proceeding, then press [Enter]'
	
	blkid | grep crypto_LUKS
	
	read ENTER
	case ENTER in
		*);;
	esac

	echo 'Now enter cryptdevice=UUID=device-UUID:cryptlvm root=/dev/MyVolGroup/root, where `device-UUID` is the UUID you wrote down earlier in the `GRUB_CMDLINE_LINUX` section, and add `lvm` to the `GRUB_PRELOAD_MODULES` section and uncomment `GRUB_ENABLE_CRYPTODISK' && sleep 10

	nano /etc/default/grub
fi

grub-mkconfig -o /boot/grub/grub.cfg

if [[ $LVMLUKS = 'Yes' ]]; then
	umount /run/lvm
fi

if [ -e ./step-2.sh ]; then
	rm ./step-2.sh
fi

exit