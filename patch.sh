#!/bin/sh
#
## builds CentOS-7-x86_64-autoinst.iso in ~
## expects ./ks.cfg present
## mucks around a bit; meant for its own VM.

## dependencies
yum install genisoimage isomd5sum syslinux wget

## if not present, grab original centos iso
if [ ! -e CentOS-7-x86_64-Minimal-1804.iso ]
then
  wget http://mirrordenver.fdcservers.net/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso
fi

## mount original
mkdir /tmp/bootiso
mount -o loop ./CentOS-7-x86_64-Minimal-1804.iso /tmp/bootiso


## make new path, copy OS
mkdir /tmp/bootisoks
cp -rv /tmp/bootiso/* /tmp/bootisoks/
chmod -R u+w /tmp/bootisoks

## copy our kickstart into new iso and edit bootloader
cp ./ks.cfg /tmp/bootisoks/isolinux/ks.cfg
sed -i 's/append\ initrd\=initrd.img/append initrd=initrd.img\ ks\=cdrom:\/ks.cfg/' /tmp/bootisoks/isolinux/isolinux.cfg

## build the new ISO9660
cd /tmp/bootisoks
mkisofs -o /tmp/boot.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -V "CentOS 7 x86_64" -R -J -v -T isolinux/. .
isohybrid /tmp/boot.iso
implantisomd5 /tmp/boot.iso


## go home, save new iso, clean up
cd
mv /tmp/boot.iso ~/CentOS-7-x86_64-autoinst.iso

umount /tmp/bootiso
rm -rf /tmp/boot.iso
rm -rf /tmp/bootiso
rm -rf /tmp/bootisoks
