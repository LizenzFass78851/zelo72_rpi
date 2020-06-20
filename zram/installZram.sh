#!/bin/bash

# Script zur Installation und Konfiguration von zram-config
# Log (/var/log) und Swap wird ins ZRAM verlegt um SD-Schreibzugriffe zu minimieren.
# https://github.com/StuartIanNaylor/zram-config

echo "*** zram-config installieren"
echo ""
sudo apt-get install git -y
cd "$HOME" || exit
git clone https://github.com/StuartIanNaylor/zram-config
cd zram-config || exit
sudo sh install.sh
echo ""
echo ""

read -p "Das System muss neu gestartet werden, Reboot durchführen (j/n)? " respntp
if [ "$respntp" != "${respntp#[Jj]}" ]; then
    echo "*** System wird neu gestartet ..."
    echo ""
    sudo reboot
fi
echo ""

echo "*** System muss neu gestartet werden, bitte manuell 'sudo reboot' ausführen!"
echo ""
echo ""