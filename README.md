# Building a CentOS7 ISO
###### Noteson building an automated CentOS-7 installation iso


The following will give us an ISO that will boot and install with no intervention.  The installation will be a minimal, listening for root on ssh to be farther configured.

Also available in this repository is a stand-alone script to perform all of the following.

## The kickstart

CentOS uses a 'kickstart' file to initiate installation.  This file is a manifest for CentOS' anaconda installer, and it provides post-install shell script functionality.  It can be placed on an http server, or on the ISO itself.  To keep things self-contained, it is nice to keep this file on the ISO itself.  This means we need patch an installation ISO.

First, we need to install the required packages.  This is written for a CentOS system.
```sh
yum install genisoimage isomd5sum syslinux wget
```

We also need a kickstart to start from.  This is mine.  It destroys all disks, installs to the first disk, enables eth0 (if your network interface is named differently, you will need to change this.  virtio corresponds with eth0), and enables sshd.  The root password is random and unknown.  You will want to replace the public ssh key with your own if you don't want me logging on!
```
#version=DEVEL

# System authorization information
auth --enableshadow --passalgo=sha512
# Use CDROM installation media
cdrom
# Use graphical install
graphical
# Run the Setup Agent on first boot
firstboot --enable
clearpart --all --drives=sda
ignoredisk --only-use=sda
# Keyboard layouts
keyboard --vckeymap=us --xlayouts='us'
# System language
lang en_US.UTF-8

# Network information
network  --bootproto=dhcp --device=eth0 --ipv6=auto --activate
network  --hostname=centos-unnamed

# Root password
rootpw --iscrypted $6$V4Y01idZyVibjE3M$e1.SlfF2njBVosAM/ZsqjXkzcEXq4OXD4oD95Bs/GMKQAJq5Or7tJZUVr7M3NzSyRNJeqXitjnSigbYljbxyS1
# System services
services --enabled="chronyd"
# System timezone
timezone America/New_York --isUtc
# System bootloader configuration
bootloader --append=" crashkernel=auto" --location=mbr --boot-drive=sda
autopart --type=lvm

reboot

%packages
@^minimal
@core
chrony
kexec-tools

%end

%addon com_redhat_kdump --enable --reserve-mb='auto'
%end


%post --log=/root/postinstall.log --interpreter=/bin/sh
mkdir /root/.ssh
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC1QYcwX7t0T5jnmrlxd68zeLX5WO4bjj/O8VdK09JN8mQFd16BasllF1vKYE+sPbT1fHyxUrL4U3q3Dwx1OnZB8KqfYVu4gJXxWOCCkc4p0xXHl0IXdJlm8YtebavKUbnYJlYAtE8xxBFj7RhYxOm2v16LTg+48vGPtlnzVGPMATDA97whLW5Dbu6nj5JfAt/RMJgynR+QGlED70inab0H/Pb2ND3buro1b3v18VCZjMMRUfckp0s/Ibpj2D81oJNF2G3lZXYGTDEXQQmzqjjIczQQYdc7WlTXYUksZIroUInNpUSJjPyghjdai4PlRUf+ggqQXavVQ5D8WZS4sbZBWibU4YV/7HMv+D5pJ8mlLzajM+ZRtOtMSrSpX5Xbj5VEFKSGsBU8Ob66mGmt6EmuimEjsXpLCbhdB9ShIhgpeSLFYcbsgWWFTE7tLtOVxShcpm/H+GlwjvBSX5wdj9pqlSCB+L4birhhvT7xZwRAxOBwywOnPkPY7KBECDbGrQbEop3EWz43Arffssrq1irixF9lIVfH7/1sojSz32FAUKHD80J/rIM2RZ9gl1MhTBglPIZHtDJVwtL3x8I+whKgqk7zkZUkgIAIu5B0gH4SEPlhPwEZOQMyV9HtSQmxo07QB1zkrf6PqV8+BIHMS8AMdxeGIAYgxhD8iMWH4ejiow== user@host" > /root/.ssh/authorized_keys
echo "PermitRootLogin without-password" >> /etc/ssh/sshd_config
%end
```

## The ISO

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
```

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
