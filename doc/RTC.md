Real-Time-Clock
===============

Die Real-Time-Clock basiert auf dem Chip DS3231 und wird über die Pins 0 (3,3V),
3 (SDA), 5 (SCL) und 6 (GND) angeschlossen. Über das I2C-Interface stellt
der Chip ein Device `/dev/rtc` für die Real-Time-Clock bereit.


Anpassung der Konfiguration
---------------------------

In der `/boot/config.txt` muss die Zeile

    dtparam=i2c_arm=on

aktiv sein und die Zeile

    dtoverlay=i2c-rtc,ds3231

zusätzlich eingetragen werden. Die Datei `/etc/modules` wird mit der
Zeile

    i2c-dev

ergänzt bzw. erstellt. Nach einem Reboot steht das I2C-Interface bereit. 
Ein Test mit

    sudo i2cdetect -y 1

aus dem Paket "i2c-tools" sollte auf Position 68 ein "UU" ausgeben.

Die Datei `/etc/udev/rules.d/85-hwclock.rules` sorgt beim Systemstart
dafür, dass die Systemzeit mit der Zeit der RTC aktualisiert wird.


Stellen der Uhr
---------------

Zuerst muss sichergestellt sein, dass der Pi die korrekte Zeit hat. Normalerweise
ist dies nach jedem Boot der Fall, wenn der Pi am Netzwerk hängt. Das lässt
sich mit dem Kommando

    date

kontrollieren (Ausgabe der aktuellen Systemzeit). Das Kommando

    sudo hwclock -w -u

schreibt die aktuelle Systemzeit (UTC) in die RTC. Das Kommando

    sudo hwclock -r

liest die RTC aus und gibt sie in lokaler Zeit aus. Mit

    sudo hwclock -s

aktualisiert man die Systemzeit auf den aktuellen Wert der RTC.

Damit die Systemzeit nicht mehr durch andere Mechanismen von Raspbian-Jessie
verstellt wird, müssen noch zwei Services abgeschaltet werden:

    sudo systemctl disable fake-hwclock.service
    sudo systemctl disable ntp.service

Der erste Service schreibt die letzte Systemzeit in eine Datei und setzt
die Systemzeit beim nächsten Boot wieder auf denselben Wert, der zweite
Service synchronisiert die Systemzeit mit einem Zeitserver im Internet.
