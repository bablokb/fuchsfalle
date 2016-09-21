Projekt Fuchsfalle
==================

Im Rahmen eines Naturschutzprojekts sollen bodenbrütende Vögel vor
Fressfeinden (Fuchs, Marder) geschützt werden. Dazu werden Fuchsfallen
aufgestellt und die gefangenen Tiere aus dem Gebiet entfernt.

Damit die Tiere in der Falle nicht verenden, überwacht ein PIC den
Status der Falle. Ist ein Tier gefangen, weckt es einen angeschlossenen
Raspberry Pi auf. Dieser sendet dann eine SMS an den Jäger, damit
dieser das befreien und die Falle zurücksetzen kann.

Die Dateien in diesem Projekt beschreiben den Aufbau und den Ablauf
sowohl auf Seite des Microkontrollers, als auch auf der Pi-Seite.


Dateien
-------

Die Dateien im Verzeichnis `netinstall` sind die Installations- und
Konfigurationsdateien für den Raspberry Pi.

TODO: Beschreibung weiterer Dateien.


Installation
------------

TODO: Beschreibung Ablauf Installation per Netinstall.


Konfiguration
-------------

Zwei Dateien müssen angepasst werden. Einmal die Datei `/etc/gammurc`.
Hier muss das richtige Modem-Device eingetragen sein.

Die zweite Konfigurationsdatei ist `/boot/fuchsfalle.cfg` (auf der ersten
Partition des fertig installierten Systems). Hier müssen eine Reihe von
Variablen angepasst werden:

  - AKTIV="0 oder 1"
  - PIN="Pin-Nummer der SIM-Karte"
  - SMS_NR="SMS-Nummer des Fallenbetreuers"
  - SMS_ADMIN="SMS-Nummer des Systemadministrators"

Die Variable `AKTIV` steuert, ob die Verarbeitung überhaupt anläuft. Die
Variable steht am Anfang auf `0`, damit das System sauber konfiguriert
werden kann. Wichtig: erst mit dem Löschen der beiden Dateien
  - `/bootnosend`
  - `/boot/nohalt`
(ebenfalls auf der ersten Partition) wird das System "scharf" geschalten.
Sind die Dateien vorhanden, läuft zwar die Verarbeitung an, aber es
wird entweder keine SMS versendet (`/boot/nosend` existiert) und/oder
das System fährt nach dem Ende der Verarbeitung nicht runter 
(`/boot/nohalt` existiert).

Ist die Nummer des Admins leer, werden die Heartbeat-Meldungen auch an
die Nummer des Fallenbetreuers gesendet.

Die Variablen `DEBUG` steuert die Ausgabe von Meldungen ins Systemlog.
Unter produktiven Bedingungen und einem stabilen Betrieb kann die
Variable leer sein (aber sie schadet auch nicht).

Mit der Variablen `ETEST` können Fehlersituationen getestet werden.
Momentan werden die Werte `NOSMS` (simuliert das Fehlschlagen des
SMS-Versands) und `LOOP` (simuliert, dass sich `fuchsfalle.sh` aufhängt)
verwendet.

