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

  - gammu, usb-modeswitch, usb-modeswitch-data, wiringpi
  - ntpdate, rfkill
  - git, i2c-tools

Die ersten Pakete sind für die Kernfunktionalität notwendig. Verschiedene
Utilities nutzen die zweiten Pakete. Die letzteren Pakete sind nicht für
den Betrieb, sondern für die einfache Installation beziehungsweise für
Diagnosezwecke notwendig.

Nach der Installation sind folgende Befehle auf dem Pi auszuführen:

    sudo su -
    git clone https://github.com/bablokb/fuchsfalle.git
    cd fuchsfalle/netinstall/config/files/root
    cp -va --parents * /

Damit sind alle Dateien an ihrem Platz. Anschließend die Konfiguration
wie unten beschrieben durchführen.


Installation per Netinstall
---------------------------

Details zur Installation per Netinstall stehen im Dokument
[doc/Netinstall.md](./doc/Netinstall.md "Installation mit Netinstall").


Konfiguration
-------------

Details zur Konfiguration stehen im Dokument [doc/Konfiguration.md](./doc/Konfiguration.md "Konfiguration").


Ablauf und Timing
-----------------

Das Dokument [doc/Ablauf.md](./doc/Ablauf.md "Ablauf und Timing") beschreibt
den Ablauf auf Pi-Seite sowie die eingestellten Zeitwerte.


Real-Time-Clock
---------------

Da das System keinen Internetanschluss hat und die einfachen GSM-Modems
in den UMTS-Sticks die Netzwerkzeit nicht abfragen können, hat das System
eine RTC auf Basis des Chips DS3231. Das Netinstall-Image konfiguriert
die RTC bei der Installation automatisch, die manuelle Einrichtung
beschreibt das Dokument [doc/RTC.md](./doc/RTC.md "Real-Time-Clock").


Aktivierung von Stromsparmechanismen
------------------------------------

Diverse Maßnahmen reduzieren den Stromverbrauch des Pi. Details dazu sind
im Dokument [doc/Stromsparen.md](./doc/Stromsparen.md "Stromsparen")
beschrieben.


Tests mit der Testplatine
-------------------------

Die Varianten für die Tests mit der Testplatine sind im Dokument
[doc/Tests.md](./doc/Tests.md "Tests") abgelegt.


Test (produktiver Ablauf)
-------------------------

Das Dokument [doc/Testplan.md](./doc/Testplan.md "Testplan") beschreibt
den Ablauf.

