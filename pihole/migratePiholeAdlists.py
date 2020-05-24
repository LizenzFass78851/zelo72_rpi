# Python-Script: migratePiholeAdlists.py - https://github.com/Zelo72/rpi (/pihole/)
#
# Beschreibung:  Migriert die Blocklisten-URLs aus adlists.list von Pihole 4 in die adlist
#                Tabelle der gravity DB von von Pihole 5.
#                URLs aus adlists.list werden nur hinzugefügt, wenn sie in der Tabelle
#                adlist noch nicht vorhanden sind.
#               
#                Damit die Blocklisten migriert werden, müssen die zu migrierenen URLs in 
#                der Datei /etc/pihole/adlists.list gespeichert werden.
#                
#                Um z.B. die aktuellen Firebog Ticked Blocklisten nach Pihole 5 zu übernehmen,
#                könnte man folgende Befehle nutzen:
#               
#                sudo wget -O /etc/pihole/adlists.list https://v.firebog.net/hosts/lists.php?type=tick
#                sudo python3 migratePiholeAdlists.py
#                sudo pihole -g
#
# Aufruf:        sudo python3 migratePiholeAdlists.py
#
# Versionshistorie:
# Version 1.0.0 - [Zelo72] - initiale Version

import sys
import sqlite3
from pathlib import Path

adlists = "/etc/pihole/adlists.list"
gravitydb = "/etc/pihole/gravity.db"

if not Path(adlists).exists():
    print(adlists + " nicht gefunden!")
    exit(1)

if not Path(gravitydb).exists():
    print(gravitydb + " nicht gefunden!")
    exit(1)

try:
    con = sqlite3.connect(gravitydb)
    file = open(adlists)
    cur = con.cursor()

    for url in file:
        cur.execute(
            'select * from adlist where address = "{d}"'.format(d=str.strip(url)))
        rec = cur.fetchall()
        if len(rec) == 0:
            s = """INSERT INTO adlist (address) VALUES ('{d}')""".format(
                d=str.strip(url))
            cur.execute(s)
            con.commit()
            print("+++ " + str.strip(url) + " hinzugefügt.")
        else:
            print("=== " + str.strip(url) + " bereits vorhanden.")

except:
    print("Unerwarteter Fehler:", sys.exc_info()[0])
    raise

finally:
    file.close()
    cur.close()
    con.close()
