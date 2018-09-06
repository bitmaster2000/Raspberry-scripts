#!/bin/bash

# Wifite installation script 0.1
# Created by Albert Kok <bitmaster2000@gmail.com>
#
# This script will download wifite and install everything it requires to run.
# Disclaimer: I take no responsibility for any kind of damage it may cause.
#             Also, this is for testing purposes only. Do not use this tool
#             on other people's networks without their consent.
#
# Tested on: Raspbian Wheezy release 2015-05-05 (clean install)
#            Ubuntu 14.04 (code name: Trusty)
#
# Notes:
#   - On a fresh system, please run this first to retrieve packages lists:
#       sudo apt-get update
#
#   - Root is required because the script installs tools outside the user scope. You
#     should not sudo the whole script to avoid ending up with files owned by root
#     in your home directory. The script will invoke sudo for you where necessary.
#
#   - To run: sh install-wifite.sh
#
# Did you use an other Linux distribution where this script works on (or not)?
# Please let me know.
#

# In detail, this script will (in this order):
#   - Download and install packages from apt for getting wifite:
#       git
#   - Download the latest wifite from git (or update it)
#   - Download and install packages from apt for running wifite:
#       reaver tshark pyrit iw ethtool
#   - Make sure /etc/reaver exists to avoid problems with reaver
#   - Download and extract cowpatty
#   - Download and install packages from apt for compiling cowpatty:
#   -   libpcap-dev openssl
#   - Compile and install cowpatty
#   - Download and extract aircrack-ng
#   - Download and install packages from apt for compiling aircrack-ng:
#       libnl-3-dev libnl-genl-3-dev libssl-dev build-essential
#   - Compile and install aircrack-ng
#   - Download the airodump-ng OUI database (or update it)
#

function e {
	stretch=$(printf "%-$(expr ${#1} + 4)s" "*")
	printf "\n\n${stretch// /*}\n* $1 *\n${stretch// /*}\n\n"
}

function yes {
	printf "\nFinished $1 $2.\n"
}

function no {
	printf "\nOh dear. Something went wrong $1 $2 for you. See the above.\n"
	while true; do
		read -p "Continue anyway?" yn
		case $yn in
			[Yy]* ) break;;
			[Nn]* ) exit 0;;
			* ) echo "Yes or no, please.";;
		esac
	done
}

#sudo apt-get install subversion
#svn checkout http://wifite.googlecode.com/svn/trunk/ wifite
#wifite is now on github

#packages required for getting wifite
e "Downloading git package required for getting wifite..."
sudo apt-get --yes install git

#download latest wifite
e "Downloading latest wifite..."
if [ ! -d "wifite/" ]; then
	echo No existing wifite found. Cloning a new one...
	git clone https://github.com/derv82/wifite.git
else
	echo Existing wifite found. Updating...
	cd wifite/
	git fetch --all
	git reset --hard origin/master
	cd ..
fi

#did we download wifite?
if [ -f "wifite/wifite.py" ]; then
	yes downloading wifite
else
	no downloading wifite
fi

#packages required for properly running wifite
e "Downloading packages required for running wifite..."
sudo apt-get --yes install reaver tshark pyrit iw ethtool

#making sure /etc/reaver exists, or wps connections will not be identified due to a bug (crazy huh)
if [ ! -d "/etc/reaver" ]; then
	sudo mkdir -p /etc/reaver
fi

#download cowpatty
e "Downloading cowpatty 2.0 source code..."
mkdir -p tools/
cd tools
wget http://downloads.sourceforge.net/project/cowpatty/cowpatty/cowpatty-2.0/cowpatty-2.0.tgz
cd ..

#did we download cowpatty?
if [ -f "tools/cowpatty-2.0.tgz" ]; then
	yes downloading cowpatty
else
	no downloading cowpatty
fi

#extract cowpatty
e "Extracting cowpatty source code..."
cd tools/
tar xzvf cowpatty-2.0.tgz
cd ..

#did we extract cowpatty?
if [ -d "tools/cowpatty" ]; then
	yes extracting cowpatty
	echo Removing tarball...
	rm tools/cowpatty-2.0.tgz
else
	no extracting cowpatty
fi

#packages required for compiling cowpatty
e "Downloading packages required for compiling cowpatty..."
sudo apt-get --yes install libpcap-dev openssl libssl-dev make

#compile cowpatty
e "Compiling cowpatty..."
cd tools/cowpatty/
make
cd ../..

#did we compile cowpatty?
if [ -f "tools/cowpatty/cowpatty" ]; then
	yes compiling cowpatty
else
	no compiling cowpatty
fi

#install cowpatty
e "Installing cowpatty..."
sudo cp tools/cowpatty/cowpatty /usr/local/bin/

#did we install cowpatty?
if [ -f "/usr/local/bin/cowpatty" ]; then
	echo /usr/local/bin/cowpatty was found.
	yes installing cowpatty
else
	echo /usr/local/bin/cowpatty was not found.
	no installing cowpatty
fi

#download aircrack-ng
e "Downloading aircrack-ng 1.2-rc2 source code..."
cd tools/
wget http://download.aircrack-ng.org/aircrack-ng-1.2-rc2.tar.gz
cd ..

#did we download aircrack-ng?
if [ -f "tools/aircrack-ng-1.2-rc2.tar.gz" ]; then
	yes downloading aircrack-ng
else
	no downloading aircrack-ng
fi

#extract aircrack-ng
cd tools/
tar xzvf aircrack-ng-1.2-rc2.tar.gz
cd ..

#did we extract aircrack-ng?
if [ -d "tools/aircrack-ng-1.2-rc2" ]; then
	yes extracting aircrack-ng
	echo Removing tarball...
	rm tools/aircrack-ng-1.2-rc2.tar.gz
else
	no extracting aircrack-ng
fi

#packages (including kernel headers!) required for compiling aircrack-ng
e "Downloading packages required for compiling aircrack-ng..."
sudo apt-get --yes install libnl-3-dev libnl-genl-3-dev libssl-dev build-essential

#compile aircrack-ng
e "Compiling aircrack-ng..."
cd tools/aircrack-ng-1.2-rc2/
make
cd ../..

#did we compile aircrack-ng?
if [ -f "tools/aircrack-ng-1.2-rc2/src/airbase-ng.o" ]; then #this is the last file
	yes compiling aircrack-ng
else
	no compiling aircrack-ng
fi

#install aircrack-ng
e "Installing aircrack-ng..."
cd tools/aircrack-ng-1.2-rc2/
sudo make install
cd ../..

#did we install aircrack-ng?
if [ -f "/usr/local/bin/aircrack-ng" ]; then #this is the most obvious file
	yes installing aircrack-ng
else
	no installing aircrack-ng
fi

#download airodump OUI file
e "Downloading airodump-ng OUI database..."
sudo airodump-ng-oui-update

e "All done! Try it out: sudo wifite/wifite.py -mac"

#end
