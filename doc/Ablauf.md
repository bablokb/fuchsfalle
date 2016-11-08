Ablauf und Timing
=================

Ablauf rc.local
---------------

Nach dem Anschalten (Stromzufuhr an) fährt der Pi hoch und startet
die Datei `/etc/rc.local`. Dieses Skript macht folgendes:

  1. Start des Skripts `/usr/local/sbin/fuchsfalle.sh`
  2. Warten auf das Ende von `/usr/local/sbin/fuchsfalle.sh`
     Dazu prüft das Skript in vorgegebenen Intervallen (`WAIT_INT`)
     den Status des Fuchsfalle-Skripts. Die maximale Wartezeit beträgt
     `WAIT_TOTAL` in Sekunden.
  3. Falls  `/usr/local/sbin/fuchsfalle.sh` immer noch läuft, wird
     es von `/etc/rc.local` hart abgebrochen. In diesem Fall
     setzt `/etc/rc.local` die GPIO22 auf Low.
  4. Setzen von GPIO10 auf High
  5. Eine Sekunde warten
  6. Shutdown auslösen


Ablauf fuchsfalle.sh
--------------------

Dieses Skript ist für die Interpretation der anliegenden Signale auf den
GPIO17 und GPIO27 verantwortlich und für den Versand der entsprehenden
SMS-Meldung.

Der Ablauf ist wie folgt:

  1. Setzen GPIO22 auf High
  2. Lesen der Konfiguration aus `/boot/fuchsfalle.cfg`
  3. Initialisierung des Modems. Das beinhaltet das Warten auf das
     konfigurierte Modemdevice sowie das Setzen der Modem-Pin.
  4. Lesen der GPIOs 17 und 27. Die Werte werden binär interpretiert
     und ein Gesamtergebnis gebilded (Werte 0-3).
  5. Versand der SMS. Die Meldungen sind in einem Array definiert
     und das Gesamtergebnis ist der Index (Offset) in diesen Array.
  6. Wenn der Versand fehlschlägt setzt das Skript GIPI22 auf Low und
     beendet sich.


Timing
------

Das Überwachungsskript `/etc/rc.local` läuft maximal `WAIT_TOTAL` Sekunden
(plus etwas Zeit für die eigentlichen Befehle). Aktuell ist
`WAIT_TOTAL=180`, d.h. die maximale Gesamtlaufzeit des Rechners ist

    Bootzeit + WAIT_TOTAL + Shutdownzeit

Die Bootzeit muss noch genauer gemessen (und optimiert) werden, die
Shutdownzeit liegt so bei 5s. `WAIT_TOTAL` könnte man etwas
optimieren (etwa auf 100-110s), der Wert sollte aber immer größer sein
als die maximale Laufzeit des Fuchsfalle-Skripts.

Das Fuchsfalle-Skript, wenn es nicht beim Versenden einer SMS hängt,
läuft für

  - Modemsuche: 30 Sekunden (10 mal 3 Sekunden)
  - Pin setzen: 30 Sekunden (10 mal 3 Sekunden)
  - SMS-Versandversuche: 30 Sekunden (10 mal 3 Sekunden)

Die Anzahl der Versuche (`MAX_V=10`) und die Wartezeit zwischen
den Versuchen (`SLEEP_V=3`) ist über die `/boot/fuchsfalle.cfg`
konfigurierbar. Bei der aktuellen Konfiguration läuft das Skript
also im schlechtesten Fall 90 Sekunden (Modem wird erst beim letzten
Versuch erkannt, Pin kann erst beim letzten Versuch gesetzt werden,
SMS-Versand scheitert zehn Mal).
