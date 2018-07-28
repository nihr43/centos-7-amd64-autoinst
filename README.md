# centos7-automation
nihr43

Tutorial on building an automated CentOS-7 installation iso

An invaluable tool for system administrators is auto-installation, which is available for many operating systems, though often poorly documented.  Combined with configuration management, automatic installation helps make physical or virtual infrastructure as programmable as containers, bringing a more sustainable approach to system administration to a wider array of platforms.  For example, instead of worrying about juggling site-wide updates, simply re-provision!


## Building a CentOS 7 ISO

CentOS uses a 'kickstart' file to initiate installation.  This file is manifest for CentOS' anaconda installer, and it provides post-install shell script functionality.  It can be placed on an http server, or on the ISO itself.  To keep things self-contained, it is nice to keep this file on the ISO itself.  This means we need to build out own installation ISO.

First, we need to install the required packages.
```sh
yum install genisoimage isomd5sum syslinux wget
```

Next, we need a copy of CentOS.
```sh
wget http://mirrordenver.fdcservers.net/centos/7/isos/x86_64/CentOS-7-x86_64-Minimal-1804.iso
```

Mount the iso in a temporary directory
```sh
mkdir /tmp/oldiso
mount -o loop ./CentOS-7-x86_64-Minimal-1804.iso /tmp/oldiso
```

Copy the contents of the original iso into a writable working directory
```sh
mkdir /tmp/newiso
cp -rv /tmp/oldiso/* /tmp/newiso/
chmod -R u+w /tmp/newiso
```

Copy our kickstart into new iso and point the bootloader at the kickstart
```sh
cp ./ks.cfg /tmp/newiso/isolinux/ks.cfg
sed -i 's/append\ initrd\=initrd.img/append initrd=initrd.img\ ks\=cdrom:\/ks.cfg/' /tmp/newiso/isolinux/isolinux.cfg

Build the new ISO9660 filesystem with the OS contents
```sh
cd /tmp/newiso
mkisofs -o /tmp/boot.iso -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -V "CentOS 7 x86_64" -R -J -v -T isolinux/. .
isohybrid /tmp/boot.iso
implantisomd5 /tmp/boot.iso
```

Return home, save the new iso, clean up.
```sh
cd
mv /tmp/boot.iso ~/CentOS-7-x86_64-autoinst.iso

umount /tmp/oldiso
rm -rf /tmp/boot.iso
rm -rf /tmp/oldiso
rm -rf /tmp/newiso
```

We now have a bootable ISO image CentOS-7-x86_64-autoinst.iso in our home directory.
