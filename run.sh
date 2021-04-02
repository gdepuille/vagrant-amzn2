#!/usr/bin/env bash

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

echo "Transformation en Vagrant avec Packer ..."
packer validate packer.json.pkr.hcl
packer build -force packer.json.pkr.hcl
