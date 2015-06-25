#!/bin/bash

echo "Disabling IPv6..."
grep -q "alias net-pf-10" /etc/modprobe.d/ipv6.conf
if [ $? -eq 0 ];
then
	sed -i "s/^.*\(alias net-pf-10\).*\$/alias net-pf-10 off/" /etc/modprobe.d/ipv6.conf
	echo "Done. You probably want to reboot now."
else
	echo "Could not find the required setting. Did you mess it up?"
	echo
	echo "To disable IPv6, please edit /etc/modprobe.d/ipv6.conf"
	echo "and make sure it contains these two lines:"
	echo
	echo "alias net-pf-10 off"
	echo "#alias ipv6 off"
	echo
	echo "The top one disables IPv6. Leave the bottom one as is."
	echo "Reboot when you're done."
	echo
fi
