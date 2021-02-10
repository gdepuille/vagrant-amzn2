#!/usr/bin/env bash

# Variables source Amazon Linux 2
FILE_SHA256="3ba323e9ccb021f97b7ce09ac7867cc34fe31533c32302c8b918cfb5dc1e2bbb"
FILE_VERSION="2.0.20210126.0"
FILE_URL="https://cdn.amazonlinux.com/os-images/${FILE_VERSION}/virtualbox"
FILE_NAME="amzn2-virtualbox-${FILE_VERSION}-x86_64.xfs.gpt.vdi"

if [ ! -d "download" ] ; then
  mkdir -p download
fi
if [ ! -d "target" ] ; then
  mkdir -p target
fi
echo " * Suppression old files ..."
rm -vf target/*

echo " * Génération seed.iso ..."
file seedconfig/*
unix2dos seedconfig/*
file seedconfig/*
genisoimage -output target/seed.iso -volid cidata -joliet -rock seedconfig/user-data seedconfig/meta-data

if [ ! -f "download/${FILE_NAME}" ] ; then
  echo " * Download Image : ${FILE_URL}/${FILE_NAME}"
  URL_FULL="${FILE_URL}/${FILE_NAME}"
  DOWNLOAD_PATH="download/${FILE_NAME}"
  wget ${URL_FULL} -O ${DOWNLOAD_PATH}

  SUM=`sha256sum ${DOWNLOAD_PATH} | cut -d ' ' -f 1`
  if [ "${FILE_SHA256}" != "${SUM}" ] ; then
    rm -vf ${DOWNLOAD_PATH}
    echo "[ERROR] Sum local ${SUM} != ${FILE_SHA256} distante"
    exit 2
  fi
else
  echo " * Image ${FILE_URL}/${FILE_NAME} déja téléchargé !"
fi

cp -vf download/${FILE_NAME} target/

# Variables de création de VM
VM_NAME="amzn2"
SATA_STORAGE="SATA Controller"
IDE_STORAGE="IDE Controller"

echo "Création de la VM VirtualBox ..."
VBoxManage createvm --name ${VM_NAME} --ostype "Linux26_64" --register
VBoxManage storagectl ${VM_NAME} --name "${SATA_STORAGE}" --add sata --controller IntelAHCI
VBoxManage storagectl ${VM_NAME} --name "${IDE_STORAGE}" --add ide
VBoxManage storageattach ${VM_NAME} --storagectl "${SATA_STORAGE}" --port 0 --device 0 --type hdd --medium target/${FILE_NAME}
VBoxManage storageattach ${VM_NAME} --storagectl "${IDE_STORAGE}" --port 0 --device 0 --type dvddrive --medium target/seed.iso
VBoxManage modifyvm ${VM_NAME} --boot1 dvd --boot2 disk --boot3 none --boot4 none
VBoxManage modifyvm ${VM_NAME} --cpus 2 --memory 2048 --vram 128
VBoxManage startvm ${VM_NAME} --type gui

echo "Attente arret de la VM (provision cloud-init) ..."
while [ $(VBoxManage showvminfo ${VM_NAME} | egrep "State.*powered off" | wc -l) -lt 1 ] ; do
  VBoxManage showvminfo ${VM_NAME} | grep State
  sleep 5
done

echo "Détach du boot seed.iso ..."
VBoxManage storageattach ${VM_NAME} --storagectl "${IDE_STORAGE}" --port 0 --device 0 --type dvddrive --medium none

echo "Export de la VM en OVA..."
VBoxManage export ${VM_NAME} -o target/amzn2.ova

echo "Suppression de la VM ..."
VBoxManage unregistervm ${VM_NAME} --delete

echo "Transformation en Vagrant avec Packer ..."
packer validate packer.json
packer build packer.json
