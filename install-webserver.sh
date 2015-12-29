#!/bin/bash

# Webserver installation script version 1 for Raspbian
# Written by Albert Kok <bitmaster2000@gmail.com>
#
# This script will install the nginx webserver, including PHP5 for
# nginx, MySQL server and client, and configure everything securely
# for you. The home for your website will become /var/www.
#
# Written for Raspbian 1.4.1 (release 2015-05-11), but will likely
# work on other Debian flavors too.
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the MIT License. See the LICENSE file for more
# information.
#

function e {
	stretch=$(printf "%-$(expr ${#1} + 4)s" "*")
	printf "\n\n${stretch// /*}\n* $1 *\n${stretch// /*}\n\n"
}

echo "Webserver installation script version 1 for Raspbian"
echo "Written by Albert Kok <bitmaster2000@gmail.com>"
echo
echo "This script will install the nginx webserver, including"
echo "PHP5 for nginx, MySQL server and client, and configure"
echo "everything securely for you. The home for your website"
echo "will become /var/www." && echo

while true; do
	read -p "Continue (y/n)? " yn
	case $yn in
		[Yy]* ) break;;
		[Nn]* ) exit 0;;
		* ) echo "Yes or no, please.";;
	esac
done

#nginx+php

e "Updating package lists..."
sudo apt-get update

e "Installing nginx and PHP5 for nginx..."
sudo apt-get install --yes nginx php-apc php5-fpm

echo && echo "Creating /var/www..."
sudo mkdir -p /var/www

e "Configuring nginx..."
echo "Rewriting /etc/nginx/sites-available/default..."
sudo cat > /etc/nginx/sites-available/default <<'nginxconf'
server {
	listen 80 default_server;
	#listen [::]:80 default_server ipv6only=on;

	root /var/www;
	server_name localhost;
	index index.php index.html index.htm;
	access_log /var/log/nginx/access.log;

	location ~\.php$ {
		fastcgi_pass unix:/var/run/php5-fpm.sock;
		fastcgi_split_path_info ^(.+\.php)(/.*)$;
		fastcgi_index index.php;
		fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
		fastcgi_param HTTPS off;
		try_files $uri =404;
		include fastcgi_params;
	}

	location / {
		try_files $uri $uri/ /index.html;
	}
}
nginxconf

echo && echo "Creating default webpage (/var/www/index.html)..."
sudo echo "It works.">/var/www/index.html
echo

sudo service nginx restart

#mysql

e "Installing MySQL database server and client..."

sudo apt-get install --yes mysql-server php5-mysql mysql-client

e "Securing MySQL..."

config=".my.cnf.$$"
command=".mysql.$$"
mysql_client=""

trap "interrupt" 1 2 3 6 15

rootpass=""
echo_n=
echo_c=

do_query() {
    echo "$1" >$command
    $mysql_client --defaults-file=$config <$command
    return $?
}

basic_single_escape() {
    echo "$1" | sed 's/\(['"'"'\]\)/\\\1/g'
}

make_config() {
    echo "# mysql_secure_installation config file" >$config
    echo "[mysql]" >>$config
    echo "user=root" >>$config
    esc_pass=`basic_single_escape "$rootpass"`
    echo "password='$esc_pass'" >>$config
}

locate_mysql_client() {
	for n in ./bin/mysql mysql;
	do
		$n --no-defaults --help > /dev/null 2>&1
		status=$?
		if test $status -eq 0;
		then
			mysql_client=$n
			return
		fi
	done
	echo "Can't find a 'mysql' client in PATH or ./bin"
	exit 1
}

interrupt() {
    echo
    echo "Aborting. Please rerun this script if you want to finish setting up your webserver!"
    echo
    cleanup
    stty echo
    exit 1
}

cleanup() {
    echo "Cleaning up..."
    rm -f $config $command
}

echo "Preparing..."
touch $config $command
chmod 600 $config $command

echo "Locating MySQL client..."
locate_mysql_client && echo

case `echo "testing\c"`,`echo -n testing` in #echo compatibility
	*c*,-n*) echo_n=   echo_c=     ;;
	*c*,*)   echo_n=-n echo_c=     ;;
	*)       echo_n=   echo_c='\c' ;;
esac

echo "In order to log into MySQL to secure it, we'll need the current"
echo "password for the MySQL root user. If you've just installed MySQL,"
echo "and you haven't set the root password yet, the password will be"
echo "blank, in which case you should just press enter here." && echo
status=1
while [ $status -eq 1 ];
do
	stty -echo
	echo $echo_n "Enter MySQL root password (or enter if none): $echo_c"
	read password
	echo
	stty echo
	if [ "x$password" = "x" ];
	then
		hadpass=0
	else
		hadpass=1
	fi
	rootpass=$password
	make_config
	do_query ""
	status=$?
done
echo "Successfully tested the password."
echo

echo && echo "Removing anonymous MySQL user..."
do_query "DELETE FROM mysql.user WHERE User='';"
if [ $? -eq 0 ];
then
	echo "  ...success!"
else
	echo "  ...failed!"
fi

echo && echo "Disabling remote MySQL root access..."
do_query "DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');"
if [ $? -eq 0 ];
then
	echo "  ...success!"
else
	echo "  ...failed! That's weird!"
fi

echo && echo "Removing MySQL test database (will fail if already done)..."
do_query "DROP DATABASE test;"
if [ $? -eq 0 ];
then
	echo "  ...success!"
else
	echo "  ...failed! But don't worry, it's probably already done, which is good."
fi

echo && echo "Removing privileges on test database (if any)..."
do_query "DELETE FROM mysql.db WHERE Db='test' OR Db='test\\_%'"
if [ $? -eq 0 ];
then
	echo "  ...success!"
else
	echo "  ...failed!"
fi

echo && echo "Reloading MySQL privilege tables..."
do_query "FLUSH PRIVILEGES;"
if [ $? -eq 0 ];
then
	echo "  ...success!"
else
	echo "  ...failed! That's really weird!"
fi

echo && cleanup

e "All done!"
echo "Everything is installed and secured."
echo "The home of your website is /var/www." && echo
ips=$(hostname -I) || true
if [ "$ips" ];
then
	echo "Try and reach the server in your webbrowser:"

	for _ip in $ips; do
		if [[ $_ip == *"."* ]];
		then
			echo "  http://$_ip"
		fi
	done
	echo "  and perhaps even http://$(hostname) (depending on your network)"
else
	echo "  Note: I was unable to find the IP address(es) of this system."
	echo "  You should enter the IP in a webbrowser to see if the webserver works."
fi
echo

#
