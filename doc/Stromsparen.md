Aktivieren von Stromsparmechanismen
===================================

Das Skript `/usr/local/sbin/fuchspower.sh` schaltet verschiedene
Stromsparmechanismen an oder aus. Gesteuert wird das Skript über
die Datei `/boot/fuchsfalle.cfg`. Dort gibt es eine Reihe von
Variablen, die den Wert Null oder Eins haben können:

    PS_NOSCREEN="0"        # 1: HDMI abschalten
    PS_NOLED="0"           # 1: LEDs abschalten
    PS_NONET="0"           # 1: Netzwerk abschalten
    PS_NOWLAN="0"          # 1: WLAN abschalten
    PS_NOBT="0"            # 1: Bluetooth abschalten

Das Skript erwartet zusätzlich einen Parameter mit Wert `an` oder `aus`.

Beim Systemstart ruft der Systemd-Service `fuchspower.service` das
Skript automatisch mit dem Parameter `an` auf. Der Service wird
einmalig mit

    sudo systemctl enable fuchspower.service

aktiviert und mit

    sudo systemctl start fuchspower.service

bzw.

    sudo systemctl stop fuchspower.service

gestartet und gestoppt.

Sowohl Start als auch Stop sowie die Konfiguration der Variablen
funktioniert auch über das Skript `fuchsctl`:

    sudo fuchsctl powersave

schaltet den Service an, ein

    sudo fuchsctl nopowersave

schaltet ihn wieder ab. Die einzelnen Variablen kann man mit

    sudo fuchsctl powerset PS_NOSCREEN 1

usw. aktivieren/deaktivieren.
