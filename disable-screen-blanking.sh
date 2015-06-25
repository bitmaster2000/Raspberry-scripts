#!/bin/bash

echo "Disabling screen blanking..."
sed -i "s/^\(BLANK_TIME\s*=\s*\).*\$/\10/" /etc/kbd/config
sed -i "s/^\(POWERDOWN_TIME\s*=\s*\).*\$/\10/" /etc/kbd/config
sudo /etc/init.d/kbd restart
echo "Done."
