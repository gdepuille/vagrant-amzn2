#!/bin/bash

set -e
set -x

if [ "$PACKER_BUILDER_TYPE" != "virtualbox-ovf" ]; then
  exit 0
fi

# Install needed package for install Guest
sudo yum -y install bzip2 dkms make gcc kernel-devel kernel-header

# Install Guest Additions with support for X
sudo yum -y install xorg-x11-server-Xorg

sudo systemctl start dkms
sudo systemctl enable dkms

sudo mount -o loop,ro ~/VBoxGuestAdditions.iso /mnt/
sudo sh /mnt/VBoxLinuxAdditions.run || :
sudo umount /mnt/
rm -f ~/VBoxGuestAdditions.iso
