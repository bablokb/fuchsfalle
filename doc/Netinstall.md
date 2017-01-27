Installation mit Netinstall
===========================

Übersicht
---------

Bei diesem Verfahren wird kein Standard-Raspbian Image als Basis des
Systems verwendet, sondern ein selbst erstelltes Image. Für die
Erstellung ist zwangsläufig ein Linuxsystem notwendig, etwa eine
Raspbian-Jessie-Lite Installation.

Folgende Schritte sind notwendig:

  1. Notwendige Pakete auf Jessie-Lite installieren
  2. Fuchsfallen-Repository clonen (falls noch nicht geschehen)
  3. Skript `tools/fufa-image` aufrufen. Das erzeugt eine Datei
     `fuchsfalle.img` mit 128MB Größe.
  4. Diese Datei z.B. mit einem USB-Stick nach Windows übertragen
  5. Mit den üblichen Mitteln (analog Raspbian) auf eine SD-Karte kopieren
  6. Karte in einen Pi einlegen, Netzwerkkabel anschließen, Strom an


Details
-------

Als Vorraussetzung sind die beiden Pakete `bzip2` und `kpartx`
notwendig, die einmalig wie üblich mit

    apt-get update
    apt-get -y install bzip2 kpartx

installiert werden müssen.

Die Installation per Netinstall läuft in mehreren Schritten ab. Zuerst
wird das Repository geclont (falls noch nicht geschehen):

    sudo su -
    git clone https://github.com/bablokb/fuchsfalle.git

Anschließend wird ein SD-Karten Image erzeugt mit

    cd fuchsfalle
    tools/fufa-image

Das Skript (immer noch als Root ausgeführt) lädt ein Netinstaller-Image
herunter und kopiert die projektspezifischen Dateien auf das Image.
Nach wenigen Minutenliegt im fuchsfalle-Verzeichnis eine Datei
`fuchsfalle.img`.

Diese Datei kopiert man wie ein normales Raspbian-Image auf eine
SD-Karte. Anschließend kommt die Karte in den Pi. Dieser sollte
per Ethernet am Router hängen. Sobald der Pi Strom hat, bootet er
und die Installation läuft los.

Die Installationsdauer ist abhängig von der Geschwindigkeit der
SD-Karte (15-90 Minuten). Nach der Installation kann man sich als
root mit dem in der Datei `netinstall/config/installer-cfg.txt`
festgelegtem Passwort anmelden.

