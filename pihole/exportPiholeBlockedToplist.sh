#!/bin/bash

if [ -z "$1" ]; then
    echo "Es wurde kein Ausgabeverzeichnis angegeben!"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Ausgabeverzeichnis $1 existiert nicht!"
    exit 1
fi

exportFile=$1/TopDomainsBlocked.txt

echo "Exportiere geblockte Domains ..."

sqlite3 /etc/pihole/pihole-FTL.db "SELECT domain, count(domain) FROM queries WHERE type IN (1,2) AND status IN(1,4,5,9,10,11) GROUP BY domain ORDER BY count(domain) DESC;" >"$exportFile"

echo "Export nach $exportFile abgeschlossen"
