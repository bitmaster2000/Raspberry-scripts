#!/bin/bash

echo "Updating package database..."
apt-get update
echo
echo "Installing figlet..."
apt-get install --yes figlet
echo
echo "Downloading cool fonts from figlet.org, please wait..."
wget --quiet --no-clobber ftp://ftp.figlet.org/pub/figlet/fonts/contributed/*.flf --directory-prefix /usr/share/figlet/
echo
echo "Done."
figlet -f graffiti It works, bitch!
