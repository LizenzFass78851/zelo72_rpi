#!/bin/bash

# Script zur Installation und Konfiguration von Unbound als Pihole DNS-Server
#
# HINWEIS/WICHTIG: Erst Pihole, dann Unbound installieren!

# Script muss als Root ausgeführt werden
if [ "$(id -u)" != "0" ]; then
    echo "Das Script muss mit Rootrechten ausgeführt werden!"
    exit 1
fi

echo "*** Unbound installieren"
echo ""
apt-get update
apt-get install unbound -y
echo ""
echo ""

echo "*** Unbound Pihole-Konfiguration und internic Root Server (root.hints) speichern"
echo ""
wget -O /etc/unbound/unbound.conf.d/pi-hole.conf https://raw.githubusercontent.com/Zelo72/rpi/master/unbound/pi-hole.conf
echo ""
wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
echo ""
echo ""

read -p "Zeitsynchronisation konfigurieren *empfohlen* (j/n)? " respntp
if [ "$respntp" != "${respntp#[Jj]}" ]; then
    echo "*** Zeitsynchronisation konfigurieren"
    echo ""
    wget -O /etc/systemd/timesyncd.conf https://raw.githubusercontent.com/Zelo72/rpi/master/unbound/timesyncd.conf
    timedatectl set-ntp true
    timedatectl set-timezone 'Europe/Berlin'
    hwclock -w
fi
echo ""
echo ""

echo "*** Script /root/updateUnboundRootHints.sh für internic Root-Server Aktualisierung speichern"
wget -O /root/updateUnboundRootHints.sh https://raw.githubusercontent.com/Zelo72/rpi/master/unbound/updateUnboundRootHints.sh
chmod +x /root/updateUnboundRootHints.sh
echo ""
read -p "Updatescript für monatliche Root-Server Aktualisierung als Cronjob einrichten *empfohlen* (j/n)? " respcron
if [ "$respcron" != "${respcron#[Jj]}" ]; then
    echo "*** Updatescript für monatliche Root-Server Aktualisierung als Cronjob eintragen"
    echo ""
    echo -e "$(crontab -l)\n 0 4 1 * * /root/updateUnboundRootHints.sh > /var/log/updateUnboundRootHints.cron.log 2>&1" | crontab -
fi
echo ""
echo ""

echo "*** Unbound neu starten"
service unbound restart
echo ""
echo ""

echo "*** Unbound DNS-Auflösung testen"
echo ""
dig pi-hole.net @127.0.0.1 -p 5335
echo ""
echo ""
echo "************************************************************************************"
echo "Abschliessende manuelle Konfiguration von Pihole:"
echo ""
echo " 1. In Pihole im Webinterface unter Settings > DNS > Custom 1 (IPv4)"
echo "    (http://pi.hole/admin/settings.php?tab=dns) 127.0.0.1#5335 als DNS konfigurieren!"
echo "    Alle anderen bereits konfigurierten DNS-Server deaktivieren!"
echo ""
echo " 2. In der /etc/dnsmasq.d/01-pihole.conf das Attribut cache-size=0 setzen, das Caching"
echo "    übernimmt Unbound!"
echo "      Befehl zum Editieren: sudo nano /etc/dnsmasq.d/01-pihole.conf"
echo "************************************************************************************"
echo ""
echo ""
