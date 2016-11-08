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


Installation auf Jessie-Lite
----------------------------

Jessie-Lite wie gewohnt installieren. Ein normales Jessie geht auch,
aber der große Softwareumfang ist nicht notwendig. Folgende Pakete
müssen nachinstalliert werden:

  - gammu
  - usb-modeswitch
  - usb-modeswitch-data
  - git

Letzteres Paket ist nicht für den Betrieb, sondern für die einfache
Installation notwendig. Anschließend folgende Befehle auf dem Pi
ausführen:

    sudo su -
    git clone https://github.com/bablokb/fuchsfalle.git
    cd fuchsfalle/netinstall/config/files
    cp -va --parents * /

Damit sind alle Dateien an ihrem Platz. Anschließend die Konfiguration
wie unten beschrieben durchführen.


Installation per Netinstall
---------------------------

TODO: Beschreibung Ablauf Installation per Netinstall.


Konfiguration
-------------

Details zur Konfiguration stehen im Dokument [doc/Konfiguration.md]
(./doc/Konfiguration.md "Konfiguration").


Ablauf und Timing
-----------------

Das Dokument [doc/Ablauf.md](./doc/Ablauf.md "Ablauf und Timing") beschreibt
den Ablauf auf Pi-Seite sowie die eingestellten Zeitwerte.


Tests mit der Testplatine
-------------------------

Die Varianten für die Tests mit der Testplatine sind im Dokument
[doc/Tests.md](./doc/Tests.md "Tests") abgelegt.

