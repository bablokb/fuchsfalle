Testplan für produktiven Einsatz
================================

Vorbereitung
------------

Installation des Systems gemäß der Anleitung in 
[./Netinstall.md] (./Netinstall.md "Installation mit Netinstall").
Nach ca. 30 Minuten ist das System per ssh oder, falls Tastatur und
Bildschirm angeschlossen sind, direkt erreichbar.

An dieser Stelle kann die `/boot/fuchsfalle.cfg` vorkonfiguriert
werden. `AKTIV` sollte auf `0` bleiben, ebenso die Variablen `PS_NOLED`
`PS_NONET` und `PS_NOSCREEN` (bei Direktzugriff per Tastatur/Bildschirm).

Diese Anleitung geht davon aus, dass die RTC auf der PIC-Platine
montiert ist und deshalb noch nicht konfigurierbar ist.


Zusammenbau
-----------

An dieser Stelle erfolgt der Zusammenbau: Raspi auf Trägerplatine mit Akku,
PIC-Board auf den Raspi. Für die Konfiguration der RTC kommt der Pi
ans Netzwerk, eventuell auch Tastatur und Bildschirm anschließen. Jetzt
den Strom per Jumper anschalten (am PIC vorbei).

Nach dem Boot einloggen und mit

    fuchsrtc

die Uhr stellen. Anschließend den Pi scharf schalten:

    fuchsctl powerset NO_SCREEN 1
    fuchsctl powerset NO_NET    1
    fuchsctl scharf
    halt -p & exit

Die ersten beiden Befehle sind optional und davon abhängig, ob das
System später noch im Zugriff bleiben soll (kann aber jederzeit direkt
in der `/boot/fuchsfalle.cfg` zurückgesetzt werden).

Anschließend den Jumper durch die Verbindung mit dem PIC ersetzen. Ab
jetzt läuft die Zeit.


Test: Falle offen, keine Unterspannung
--------------------------------------

Testklappe entsprechend positionieren. Ungefähr 8 Minuten warten.

**Erwartetes Ergebnis: der Pi fährt in dieser Zeit nicht hoch.**


Test: Falle zu, keine Unterspannung
-----------------------------------

Testklappe entsprechend positionieren. Warten...

** Erwartetes Ergebnis: der Pi fährt nach ca. 5 Minuten hoch und versendet
eine entsprechende SMS.**

Weitere 10 Minuten warten.

**Erwartetes Ergebnis: der Pi fährt in dieser Zeit nicht hoch.**


Test: Falle offen, Unterspannung
--------------------------------

Testklappe neu positionieren. Reset drücken. Strom auf Unterspannung setzen.

** Erwartetes Ergebnis: der Pi fährt nach ca. 5 Minuten hoch und versendet
eine entsprechende SMS.**

Weitere 10 Minuten warten.

**Erwartetes Ergebnis: der Pi fährt in dieser Zeit nicht hoch.**


Test: Falle zu, Unterspannung
-----------------------------

Testklappe neu positionieren. Reset drücken.

** Erwartetes Ergebnis: der Pi fährt nach ca. 5 Minuten hoch und versendet
eine entsprechende SMS.**

Weitere 10 Minuten warten.

**Erwartetes Ergebnis: der Pi fährt in dieser Zeit nicht hoch.**

