#!/bin/bash

if [ -z "$1" ]; then
    echo "Es wurde kein Ausgabeverzeichnis angegeben!"
    exit 1
fi

if [ ! -d "$1" ]; then
    echo "Ausgabeverzeichnis $1 existiert nicht!"
    exit 1
fi

exportFile=$1/TopDomainsPermitted.txt

echo "Exportiere aufgerufene Domains ..."

sqlite3 /etc/pihole/pihole-FTL.db "SELECT domain, count(domain) FROM queries WHERE status IN(2,3) GROUP BY domain ORDER BY count(domain) DESC;" >"$exportFile"

echo "Export nach $exportFile abgeschlossen"
