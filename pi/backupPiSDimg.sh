#!/bin/bash

# Script: backupPiSDimg.sh - https://github.com/Zelo72/rpi (/pi/)
#
# Beschreibung: Das Script sichert mittels dd die komplette SD Karte des laufenden Raspberry Pi in eine Image-Datei.
#               Das gesicherte Image lässt sich z.B. balena etcher oder dd wieder auf eine SD-Karte schreiben.
#
#               HINWEIS: Da die Sicherung online während des laufendnen Pi-Systems durchgeführt wird, kann es zu 
#               inkonsistenten Daten in der Sicherungs-Datei kommen wenn während der Sicherung viele Schreibvorgänge
#               auf der SD erfolgen. Möchte man einen konsistenten, sicheren Backup erstellen, muss man diesen 
#               offline an einem anderen System (Linux/Windows/Mac) durch Sichern der SD-Karte durchführen. 
#
# Aufrufparameter: 1. Backupverzeichnis              --> Pfad in dem das Image abgelegt werden soll
#                  2. Bereinigungsintervall in Tagen --> (optional) Logs und Images älter als
#                                                                   X Tage löschen.
#                                                                   Standartwert ist: 60 Tage
#                  3. E-Mail Adresse                 --> (optional) Adresse an die der Backup-Bericht
#                                                                   gesendet werden soll.
#
# Aufruf:          sudo ./backupPiSDimg.sh /mnt/nas/bak/
#                  optional: sudo ./backupPiSDimg.sh /mnt/nas/bak/ 30
#                            sudo ./backupPiSDimg.sh /mnt/nas/bak/ 60 name@domain.xy
#
# Ausgabedateien: /var/log/pihole/Ymd_backupPiSDimg.sh.log  --> Logfile
#                 /var/log/pihole/backupPiSDimg.cron.log    --> Logifile des Cron-Jobs
#                 /.../Backup-raspberrypi-Ymd.img           --> Backup Image-Datei
#
# Installation:   1. Script downloaden:
#                    wget -N https://raw.githubusercontent.com/Zelo72/rpi/master/pi/backupPiSDimg.sh
#                 2. Script mittels sudo chmod +x backupPiSDimg.sh ausführbar machen.
#
# Installation:   1. Script mittels sudo cp backupPiSDimg.sh /root nach /root kopieren.
# (als Cron-Job)  2. Script mittels sudo chmod +x /root/backupPiSDimg.sh ausführbar machen.
#                 3. Cron-Job mit sudo crontab -e erstellen
#                    Am Ende der Datei z.B. folgendes einfügen um das Script monatlich am 1. um 01:45 Uhr
#                    auszuführen:
#
#                    45 1 1 * * /root/backupPiSDimg.sh /mnt/nas/bak/ > /var/log/pihole/backupPiSDimg.cron.log 2>&1
#
#                  4. Datei speichern und schliessen (im nano Editor: Strg+o/Enter/Strg+x).
#
# Versionshistorie:
# Version 1.0.0 - [Zelo72] - initiale Version
#

# Prüfen ob das Script als root ausgeführt wird
if [ "$(id -u)" != "0" ]; then
    echo "Das Script muss mit Rootrechten ausgeführt werden!"
    exit 1
fi

# Prüfen ob ein Backupverzeichnis angegeben wurde
if [ -z "$1" ]; then
    echo "Es wurde kein Backupverzeichnis angegeben!"
    exit 1
fi

# Prüfen ob das Backupverzeichnis existiert
if [ ! -d "$1" ]; then
    echo "Backupverzeichnis $1 existiert nicht!"
    exit 1
fi

# Bereiniung nach x Tagen, Default: 60 Tage
cleaningInterval=60
# Prüfen ob ein Bereinigungsintervall in Tagen als 2. Aufrufparameter mitgegeben wurde.
if [ -n "$2" ]; then
    cleaningInterval=$2
fi

# *** Initialisierung ***

# Logging initialisieren
logDir=/var/log/pihole
log=$logDir/$(date +'%Y%m%d')_backupPiSDimg.sh.log
mkdir -p $logDir

# Hilfsfunktion zum loggen
writeLog() {
    echo -e "[$(date +'%Y.%m.%d-%H:%M:%S')]" "$*" | tee -a "$log"
}
writeLog "[I] Start | Logfile: $log"

# Logverzeichnis bereinigen, Logs älter als n Tage werden gelöscht.
writeLog "[I] Bereinige Logverzeichnis $logDir ..."
find $logDir -daystart -type f -mtime +"$cleaningInterval" -name \*backupPiSDimg\*.log -exec rm -v {} \;
writeLog "[I] Logverzeichnis $logDir bereinigt."

# Variablen
backupDir=$1
sd=/dev/mmcblk0

# *** Raspberry Pi Backup ***

writeLog "[I] Führe Raspberry Pi Backup durch ..."
cd "$backupDir" || exit
backupfile="Backup-$(hostname)-$(date +'%Y%m%d').img"

writeLog "[I] Erstelle Image $backupfile von $sd in $backupDir, dies wird einige Zeit dauern ..."
dd if=$sd of="$backupDir/$backupfile" bs=1MB
if [ ! $? ]; then
    writeLog "[E] Fehler beim Backup, Exitcode: $?"
else
    writeLog "[I] Backup erfolgreich durchgeführt."
fi

# Alte Image-Dateien bereinigen, Images älter als n Tage werden gelöscht.
writeLog "[I] Bereinige Images im Backupverzeichnis $backupDir älter als $cleaningInterval Tage ..."
find "$backupDir" -daystart -type f -mtime +"$cleaningInterval" -name Backup-"$(hostname)"-\*.img -exec rm -v {} \;
writeLog "[I] Alte Backupimages unter $backupDir wurden bereinigt."

# Aufrufparameter 3: sudo ./backupPiSDimg.sh /mnt/nas/bak/ 60 name@domain.xy
email="$3"

# Mail mit RaspberryPi Backup-Bericht wird nur versendet wenn beim Aufruf des Scriptes eine
# Mailadresse als Parameter 3 mit uebergeben wurde!
if [ -n "$email" ]; then
    writeLog "[I] E-Mail RaspberryPi Backup-Bericht $backupfile wird an $email versendet ..."
    mail <"$log" -s "RaspberryPi Backup-Bericht $backupfile" "$email"

    # Pruefen ob der E-Mailversand fehlgeschlagen ist
    if [ $? -ne 0 ]; then
        writeLog "[E] E-Mailversand an $email fehlgeschlagen!"
    else
        writeLog "[I] E-Mailversand an $email erfolgreich."
    fi
fi

writeLog "[I] Ende | Logfile: $log"
