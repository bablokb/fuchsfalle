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

Zwei Dateien müssen angepasst werden. Einmal die Datei `/etc/gammurc`.
Hier muss das richtige Modem-Device eingetragen sein.

Die zweite Konfigurationsdatei ist `/boot/fuchsfalle.cfg` (auf der ersten
Partition des fertig installierten Systems). Hier müssen eine Reihe von
Variablen per Editor angepasst werden:

  - AKTIV="0 oder 1"
  - PIN="Pin-Nummer der SIM-Karte"
  - SMS_NR="SMS-Nummer des Fallenbetreuers"
  - SMS_ADMIN="SMS-Nummer des Systemadministrators"

Die Variable `AKTIV` steuert, ob die Verarbeitung überhaupt anläuft. Die
Variable steht am Anfang auf `0`, damit das System sauber konfiguriert
werden kann. 

Bei `AKTIV=0` fährt das System hoch, setzt GPIO22 auf low und bleibt
hochgefahren, d.h. es wird erst gar nicht versucht, eine SMS zu
senden.

Um besser testen zu können, gibt es die beiden Dateien

  - `/bootnosend`
  - `/boot/nohalt`

Die Existenz der ersten Datei steuert den SMS-Versand. Solange es die
Datei gibt (Inhalt egal), wird der Versand nicht ausgeführt, sondern
nur simuliert.

Die Existenz der zweiten Datei steuert das Verhalten am Ende der
Verarbeitung. Solange die Datei existiert, fährt das System nicht runter,
man kann sich also auch nach der Verarbeitung anmelden und die
Logmeldungen ansehen. Auch wenn das System nicht runter fährt werden
alle GPIOs entsprechend den Vorgaben gesetzt!

Wichtig: erst mit dem Löschen der beiden Dateien wird das System "scharf" 
geschalten.

Ist die Nummer des Admins leer, werden die Heartbeat-Meldungen auch an
die Nummer des Fallenbetreuers gesendet.

Die Variablen `DEBUG` steuert die Ausgabe von Meldungen ins Systemlog.
Unter produktiven Bedingungen und einem stabilen Betrieb kann die
Variable leer sein (aber sie schadet auch nicht).

Mit der Variablen `ETEST` können Fehlersituationen getestet werden.
Momentan werden die Werte `NOSMS` (simuliert das Fehlschlagen des
SMS-Versands) und `LOOP` (simuliert, dass sich `fuchsfalle.sh` aufhängt)
verwendet.


Tests mit der Testplatine
-------------------------

Alle Testfälle gehen davon aus, dass der Pi aus dem Status "stromlos"
gestartet wird.

  1. Fall (AKTIV=`0`)

  Bei `AKTIV=0` fährt das System hoch, setzt GPIO22 auf low und bleibt
  hochgefahren, d.h. es wird erst gar nicht versucht, eine SMS zu senden
  aber an der Testplatine sieht man das "Ergebnis".

  2. Fall (AKTIV=`1`)

  In diesem Fall sucht der Pi nach dem Modem, setzt dort die Pin und
  simuliert den Versand der richtigen Meldung (je nach Konfiguration
  der Testplatine). Anschließend setzt er alle GPIOs, fährt aber nicht
  runter. Die Testplatine sollte den richtigen Status zeigen. Im
  Systemlog stehen die Meldungen:

  `sudo journalctl SYSLOG_IDENTIFIER=rc.local`
  `sudo journalctl SYSLOG_IDENTIFIER=fuchsfalle.sh`

  oder mit (nur Meldungen von fuchsfalle.sh):

  `sudo less /var/log/fuchsfalle.log`

  3. Fall (AKTIV=`1`, Datei `/boot/nosend` gelöscht/umbenannt)

  Existiert die Datei `/boot/nosend` nicht, so passiert dasselbe
  wie im 2.Fall mit dem einzigen Unterschied, dass der Pi tatsächlich
  die SMS verschickt. Wenn man sicher ist, dass der SMS-Versand klappt,
  dann kann man die Datei `/boot/nosend` wieder herstellen per
  `sudo touch /boot/nosend`, das spart dann bei den weiteren Tests die
  SMS-Kosten.

  4. Fall (wie 3.Fall aber zusätzlich ohne Datei `/boot/nohalt`)

  Das ist das eigentliche Produktivszenario: die SMS wird verschickt
  und der Pi fährt wieder runter.

  Wenn etwas nicht so funktioniert hat wie man möchte, dann muss man sich
  die Logs ansehen.

  An die Logs kommt man jetzt aber etwas schwieriger ran, weil der Pi ja
  wieder sofort runterfährt. Entweder man entnimmt die Karte und ändert
  wahlweise AKTIV=0 oder erstellt wieder die /boot/nohalt (das müsste
  sogar auf einem Windows-PC gehen). Beim nächsten Start bleibt der Pi
  wieder oben und man kann sich die Logs ansehen.

  5. Fall und Folgende

  Das sind alles Variationen, z.B. durch ändern der
  Einstellung der Testplatine. Fehlersituationen kööen über die
  ETEST-Variable in der `/boot/fuchsfalle.cfg` simuliert werden.
