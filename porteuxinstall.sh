#!/bin/bash
# created by isaachhk02
# 


disk=""
biostype=""

wipe_disk()
{
  lsblk
  echo "Write your device: (ex: sda without /dev)"
  read disk
  if [ -z $disk ]; then
    echo "You need write a device!"  
  #zenity --error --text="You need select a device!"
    wipe_disk
  else
    echo $disk
    umount /mnt/$disk*
    echo "Wiping /dev/$disk"
    wipefs -a "/dev/$disk"
    echo "Wipe done!"
    partition_setup
  fi
}
partition_setup()
{
  echo "Making partitions"
  if [ $biostype == "UEFI" ]; then 
    parted -s /dev/"$disk" mklabel gpt
    parted -s /dev/"$disk" mkpart primary fat32 1MiB 512MiB
    echo "Setting partition 1 as efi flag!"
    parted -s /dev/"$disk" set 1 esp on
    echo "Creating root partition"
    parted -s /dev/"$disk" mkpart primary ext4 512MiB 100%
    echo "Done!"
  else
    parted -s /dev/"$disk" mklabel dos
    parted -s /dev/"$disk" mkpart primary ext4 1MiB 100%
    parted -s /dev/"$disk" set 1 boot on
  fi
  echo "Partition setup done! Starting copying files..."
  copy_files
}
copy_files()
{
  if [ $disk == "nvme0n1" ]; then
    mkfs.vfat -F 32 /dev/"$disk""p1"
    mkfs.ext4 /dev/"$disk""p2"
    mount /dev/"$disk""p1" /mnt/"$disk""p1"
    mount /dev/"$disk""p2" /mnt/"$disk""p2"
    cp -rv /mnt/sr0/boot /mnt/sr0/EFI /mnt/"$disk""p1"
    cp -rv /mnt/sr0/porteux /mnt/"$disk""p2"
    echo "Install completed! please reboot!"
  else
    mkfs.vfat -F 32 /dev/"$disk""1"
    mkfs.ext4 /dev/"$disk""2"
    mount /dev/"$disk""1" /mnt/"$disk""1"
    mount /dev/"$disk""2" /mnt/"$disk""2"
    cp -rv /mnt/sr0/boot /mnt/sr0/EFI /mnt/"$disk""1"
    cp -rv /mnt/sr0/porteux /mnt/"$disk""2"
    
    echo "Install completed! please reboot!"
  fi
  umount -l /mnt/"$disk"
}

select_bios_type()
{
  echo "Options available:"
  echo "BIOS"
  echo "UEFI"
  echo "Write you installation type:"
  read biostype
  if [ -z $biostype ]; then
    select_bios_type
  else
    echo $biostype
    wipe_disk
  fi
}


checkRoot()
{
  if [[ $EUID != 0 ]]; then
    echo "You must run as root user!"
  else
    select_bios_type
  fi
}
checkRoot
