# Python-Script: migratePiholeAuditLog.py - https://github.com/Zelo72/rpi (/pihole/)
#
# Beschreibung:  Migriert die AuditLog-Domains aus auditlog.list von Pihole 4 in die domain_audit
#                Tabelle von Pihole 5.
#                Der AuditLog wird beim Update von Version 4 auf Version 5 nicht automatisch mit
#                migriert.
#                Domains aus auditlog.list werden nur hinzugefügt, wenn sie in der Tabelle
#                domain_audit noch nicht vorhanden sind.
#
# Aufruf:        sudo python3 migratePiholeAuditLog.py
#
# Versionshistorie:
# Version 1.0.0 - [Zelo72] - initiale Version

import sys
import sqlite3
from pathlib import Path

auditlog = "/etc/pihole/auditlog.list"
gravitydb = "/etc/pihole/gravity.db"

if not Path(auditlog).exists():
    print(auditlog + " nicht gefunden!")
    exit(1)

if not Path(gravitydb).exists():
    print(gravitydb + " nicht gefunden!")
    exit(1)

try:
    con = sqlite3.connect(gravitydb)
    file = open(auditlog)
    cur = con.cursor()

    for domain in file:
        cur.execute(
            'select * from domain_audit where domain = "{d}"'.format(d=str.strip(domain)))
        rec = cur.fetchall()
        if len(rec) == 0:
            s = """INSERT INTO domain_audit (domain) VALUES ('{d}')""".format(
                d=str.strip(domain))
            cur.execute(s)
            con.commit()
            print("+++ " + str.strip(domain) + " hinzugefügt.")
        else:
            print("=== " + str.strip(domain) + " bereits vorhanden.")

except:
    print("Unerwarteter Fehler:", sys.exc_info()[0])
    raise

finally:
    file.close()
    cur.close()
    con.close()
