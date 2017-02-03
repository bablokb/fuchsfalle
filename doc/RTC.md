Real-Time-Clock
===============

Die Real-Time-Clock basiert auf dem Chip DS3231 und wird über die Pins 0 (3,3V),
3 (SDA), 5 (SCL) und 6 (GND) angeschlossen. Über das I2C-Interface stellt
der Chip ein Device `/dev/rtc` für die Real-Time-Clock bereit.


Anpassung der Konfiguration
---------------------------

Die hier beschriebenen Anpasssungen gelten allgemein für Raspbian-Jessie.
Wird das System per Netinstall installiert, dann entfallen diese manuellen
Anpassungen (die Uhr muss aber trotzdem wie unten beschrieben gestellt werden).

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

aus dem Paket "i2c-tools" (nur für Diagnosezwecke notwendig) sollte auf
Position 68 ein "UU" ausgeben.

Die (neu zu erstellende) Datei `/etc/udev/rules.d/85-hwclock.rules`
sorgt beim Systemstart dafür, dass die Systemzeit mit der Zeit der
RTC aktualisiert wird:

    KERNEL=="rtc0", RUN+="/sbin/hwclock -s"


Stellen der Uhr
---------------

Das Skript `/usr/local/sbin/fuchsrtc` erledigt das erstmalige Stellen
der Uhr automatisch. Nach dem allerersten
Boot muss es aufgerufen werden und setzt eine funktionsfähige
Internetverbindung voraus. Die folgenden Schritte beschreiben den
Ablauf, den das Skript automatisiert.

Zuerst muss sichergestellt sein, dass der Pi die korrekte Zeit hat. Normalerweise
ist dies nach jedem Boot der Fall, wenn der Pi am Netzwerk hängt. Das lässt
sich mit dem Kommando

    date

kontrollieren (Ausgabe der aktuellen Systemzeit). Stimmt die Zeit nicht,
konnte der NTP-Daemon die Zeit nicht synchronisieren. Hier muss man entweder
etwas warten oder man installiert das Paket `ntpdate` nach und führt den
Befehl

    sudo ntpdate 2.debian.pool.ntp.org

aus. Das Kommando

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
