Das GSM-Modul SIM800L
=====================

Für den SMS-Versand braucht es keinen ausgewachsenen UMTS-Stick, es langt ein
kostengünstiges GSM-Modul wie das SIM800L. Das Modul unterstützt zwar nur
G2, das ist aber für den SMS-Versand ausreichend.

Schon für unter 10€ gibt es das Modul auf einer kleinen Trägerplatine, die
die wichtigsten Anschlüsse nach außen führt. Angeschlossen an den Pi wird
das Modul über die GPIO-Pin GND, TxD, RxD und einen weiteren Pin für den
Reset (RST).

Softwareseitig ist das Modul schnell in Betrieb genommen. Zuerst muss der
UART aktiviert und die serielle Konsole abgeschaltet werden.

In die `/boot/config.txt` kommt eine zusätzliche Zeile:

    enable_uart=1

Desweiteren muss man in der `/boot/cmdline.txt` der String
`console=serial0,115200` entfernen. Nach einem Reboot ist die
UART-Schnittstelle frei.

Gammu findet das serielle Modem nicht automatisch mit `gammu-detect`.
Deswegen muss die `/etc/gammurc` manuell mit folgendem Inhalt erstellt
werden:

    [gammu]
    device = /dev/serial0
    name = SIM800L GSM module
    connection = at
    logfile = /var/log/gammu.log
    logformat = nothing

Die GPIO für Reset konfiguriert man zum Beispiel mit Wiring-Pi auf High:

    sudo gpio -g mode 18 out
    sudo gpio -g write 18 1

Eine weitergehende Konfiguration ist nicht notwendig. Ein Test, ob alles
funktioniert zeigt das Kommando

    sudo gammu identify

Für die Eingabe der PIN sowie dem Versand einer Testnachricht setzt man
die folgenden Befehle ab:

    sudo gammu entersecuritycode PIN -
    sudo gammu sendsms TEXT 12345678 -text "Dies ist eine Testnachricht"

Rootrechte sind nicht notwendig, wenn der Benutzer Mitglied in der Gruppe
"dialout" ist.