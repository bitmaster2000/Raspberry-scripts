#!/bin/bash

echo "Enabling IPv6..."
sed -i "s/^\(alias net-pf-10 off\).*\$/#\1/" /etc/modprobe.d/ipv6.conf
echo "Done. You probably want to reboot now."
