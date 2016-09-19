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
Partition des fertig installierten Systems). Hier müssen insbesondere
die Nummer der Falle, die SMS-Nummer und die PIN der SIM-Karte 
engetragen werden.

Erst mit dem Löschen der beiden Dateien `/boot/nohalt` und `/bootnosend`
(ebenfalls auf der ersten Partition) wird das System "scharf" geschalten.
