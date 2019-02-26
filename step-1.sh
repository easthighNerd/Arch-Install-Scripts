ls /sys/firmware/efi/efivars

timedatectl set-ntp true

lsblk

echo 'Please choose the disk you want to partition (in lowercase) (i.e. sda)'
read SDX
case "$SDX" in
	*);;
esac

echo 'Please remember to pick GPT' && sleep 2

cfdisk -z /dev/$SDX

echo 'Please select your partition setup'
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

if [[ $PARTITION = 'BIOS' ]]; then
	mkfs.ext4 /dev/$SDX\2
	mkswap /dev/$SDX\3 && swapon /dev/$SDX\3
	mount /dev/$SDX\2 /mnt
fi

if [[ $PARTITION = 'UEFI' ]]; then
	mkfs.fat -F32 /dev/$SDX\1
	mkfs.ext4 /dev/$SDX\2
	mkswap /dev/$SDX\3 && swapon /dev/$SDX\3
	mkdir /mnt/boot && mount /dev/$SDX\1 /mnt/boot
	mount /dev/$SDX\2 /mnt
fi

if [[ $PARTITION = 'LVM on LUKS with BIOS' ]]; then
	cryptsetup luksFormat --type luks2 /dev/$SDX\2
	cryptsetup open /dev/$SDX\2 cryptlvm
	pvcreate /dev/mapper/cryptlvm
	vgcreate MyVolGroup /dev/mapper/cryptlvm
	
	echo 'Please enter the ammount of RAM on your system (i.e. 8G)'
	read RAM
	case $RAM in
		*);;
	esac

	lvcreate -L $RAM MyVolGroup -n swap
	lvcreate -l 100%FREE MyVolGroup -n root
	mkfs.ext4 /dev/$SDX\2
	mkfs.ext4 /dev/MyVolGroup/root
	mkswap /dev/MyVolGroup/swap
	mount /dev/MyVolGroup/root /mnt
	mkdir /mnt/boot && mount /dev/$SDX\2 /mnt/boot
	swapon /dev/MyVolGroup/swap
fi

if [[ $PARTITION = 'LVM on LUKS with EFI' ]]; then
	cryptsetup luksFormat --type luks2 /dev/$SDX\2
	cryptsetup open /dev/$SDX\2 cryptlvm
	pvcreate /dev/mapper/cryptlvm
	vgcreate MyVolGroup /dev/mapper/cryptlvm
	
	echo 'Please enter the ammount of RAM on your system (i.e. 8G)'
	read RAM
	case $RAM in
		*);;
	esac

	lvcreate -L $RAM MyVolGroup -n swap
	lvcreate -l 100%FREE MyVolGroup -n root
	mkfs.fat -F32 /dev/$SDX\1
	mkfs.ext4 /dev/MyVolGroup/root
	mkswap /dev/MyVolGroup/swap
	mount /dev/MyVolGroup/root /mnt
	mkdir /mnt/boot && mount /dev/$SDX\1 /mnt/boot
	swapon /dev/MyVolGroup/swap
fi

echo 'Are you using WiFi or Ethernet for your network connection?'
select NETWORK in 'WiFi' 'Ethernet'
do
	case $NETWORK in
		'WiFi'|'Ethernet')
			break
			;;
		*)
			echo 'Please select either WiFi or Ethernet'
			;;
	esac
done

echo 'Are you using BIOS or EFI?'
select EFIBIOS in 'BIOS' 'EFI'
do
	case $EFIBIOS in
		'BIOS'|'EFI')
			break
			;;
		*)
			echo 'Please select either BIOS or EFI'
			;;
	esac
done

echo 'Are you using an Intel or AMD CPU?'
select CPU in 'intel' 'amd'
do
	case $CPU in
		'intel'|'amd')
			break
			;;
		*)
			echo 'Please select either Intel or AMD'
			;;
	esac
done

if [[ $NETWORK = 'WiFi' ]]; then
	if [[ $EFIBIOS = 'EFI' ]]; then
		pacstrap /mnt base base-devel git wget nano grub $CPU-ucode efibootmgr sudo dialog wpa_supplicant
	else
		pacstrap /mnt base base-devel git wget nano grub $CPU-ucode sudo dialog wpa_supplicant
	fi
else
	if [[ $EFIBIOS = 'EFI' ]]; then
		pacstrap /mnt base base-devel git wget nano grub $CPU-ucode efibootmgr sudo
	else
		pacstrap /mnt base base-devel git wget nano grub $CPU-ucode sudo
	fi
fi

genfstab -U /mnt >> /mnt/etc/fstab

if [[ $PARTITION = 'LVM on LUKS with BIOS' ]] || [[ $PARTITION = 'LVM on LUKS with EFI' ]]; then
	mkdir /mnt/hostrun && mount --bind /run /mnt/hostrun
	arch chroot /mnt /bin/bash
else
	arch-chroot /mnt
fi

umount -R /mnt

shutdown now