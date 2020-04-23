#!/bin/bash

# Script: updateUnboundRootHints.sh - https://github.com/Zelo72/rpi (/unbound/)
#
# Beschreibung:   Aktualisiert die Unbound root.hints (Rootserver) von internic.net. Das Script sollte
#                 monatlich ausgeführt werden.
#
# Aufruf:         sudo ./updateUnboundRootHints.sh
#
# Ausgabedateien: /var/log/updateUnboundRootHints.sh.log   --> Logfile
#                 /var/log/updateUnboundRootHints.cron.log --> logfile cron job
#
# Installation:   1. Script downloaden:
#                    wget https://raw.githubusercontent.com/Zelo72/rpi/master/unbound/updateUnboundRootHints.sh
#                 2. Script mittels sudo chmod +x updateUnboundRootHints.sh ausführbar machen.
#
# Installation:   1. Script mittels sudo cp updateUnboundRootHints.sh /root nach /root kopieren.
# (als Cron-Job)  2. Script mittels sudo chmod +x /root/updateUnboundRootHints.sh ausfuehrbar machen.
#                 3. Cron-Job mit sudo crontab -e erstellen
#                    Am Ende der Datei z.B. folgendes einfuegen um das Script monatlich am 1.
#                    um 04:00 Uhr auszuführen:
#
#                     0 4 1 * * /root/updateUnboundRootHints.sh > /var/log/updateUnboundRootHints.cron.log
#
#                  4. Datei speichern und schliessen. (im nano Editor: Strg+o/Enter/Strg+x).

# Prüfen ob das Script als root ausgefuehrt wird
if [ "$(id -u)" != "0" ]; then
    echo "Das Script muss mit Rootrechten ausgeführt werden!"
    exit 1
fi

# Logging initialisieren
logDir=/var/log/
log=$logDir/updateUnboundRootHints.sh.log
if test -f "$log"; then rm "$log"; fi

# Hilfsfunktion zum loggen
writeLog() {
    echo -e "[$(date +'%Y.%m.%d-%H:%M:%S')]" "$*" | tee -a "$log"
}
writeLog "[I] Start | Logfile: $log"

writeLog "[I] Hole named.root (Rootserver) von internic.net ..."
wget -O /var/lib/unbound/root.hints https://www.internic.net/domain/named.root
if [[ $? -ne 0 ]]; then
    writeLog "[E] named.root von internic.net konnte nicht heruntergeladen werden!"
    exit 1
fi

writeLog "[I] Starte den Unbound Service neu ..."
service unbound restart
writeLog "[I] Ende | Logfile: $log"
