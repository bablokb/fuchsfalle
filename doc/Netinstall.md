Installation mit Netinstall
===========================

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

