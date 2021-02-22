#!/bin/bash

set -e
set -x

env

if [ "${PACKER_BUILDER_TYPE}" != "virtualbox-ovf" ] || [ ! -f "/tmp/VBoxGuestAdditions.iso" ]; then
  exit 0
fi

# Install needed package for install Guest
yum -y install bzip2 dkms make gcc kernel-devel-$(uname -r) kernel-header-$(uname -r)

# Install Guest Additions with support for X
yum -y install xorg-x11-server-Xorg

systemctl start dkms
systemctl enable dkms

mount -o loop,ro /tmp/VBoxGuestAdditions.iso /mnt/
sh /mnt/VBoxLinuxAdditions.run || :
umount /mnt/
rm -f /tmp/VBoxGuestAdditions.iso
