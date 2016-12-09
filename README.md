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
    cd fuchsfalle/netinstall/config/files/root
    cp -va --parents * /

Damit sind alle Dateien an ihrem Platz. Anschließend die Konfiguration
wie unten beschrieben durchführen.


Installation per Netinstall
---------------------------

Als Vorraussetzung sind die beiden Pakete `bzip2` und `kpartx`
notwendig, die einmalig wie üblich mit

    apt-get update
    apt-get -y install bzip2 kpartx

installiert werden müssen.

Die Installation per Netinstall läuft in mehreren Schritten ab. Zuerst
wird das Repository geclont:

    sudo su -
    git clone https://github.com/bablokb/fuchsfalle.git

Anschließend wird ein SD-Karten Image erzeugt mit

    cd fuchsfalle
    tools/fufa-image

Das Skript lädt ein Netinstaller-Image herunter und kopiert die
projektspezifischen Dateien auf das Image. Nach wenigen Minuten
liegt im fuchsfalle-Verzeichnis eine Datei `fuchsfalle.img`.

Diese Datei kopiert man wie ein normales Raspbian-Image auf eine
SD-Karte. Anschließend kommt die Karte in den Pi. Dieser sollte
per Ethernet am Router hängen. Sobald der Pi Strom hat, bootet er
und die Installation läuft los.

Die Installationsdauer ist abhängig von der Geschwindigkeit der
SD-Karte (15-90 Minuten). Nach der Installation kann man sich als
root mit dem in der Datei `netinstall/config/installer-cfg.txt`
festgelegtem Passwort anmelden.


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

