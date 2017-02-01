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

Jetzt erfolgt der Zusammenbau: Raspi auf Trägerplatine mit Akku,
PIC-Board auf den Raspi. Das dreiadrige Kabel vom PIC wird nicht
angeschlossen.

Für die Konfiguration der RTC kommt der Pi ans Netzwerk, eventuell auch
Tastatur und Bildschirm anschließen. Jetzt den Strom anschalten:
Ein Jumper in der Bu2 verbindet Gate mit Masse und schaltet den Mosfet T1
ein. Damit läuft der Konverter für den Pi an und versorgt diesen
mit Dauerstrom.

Nach dem Boot einloggen und mit

    fuchsrtc

die Uhr stellen. Anschließend den Pi scharf schalten:

    fuchsctl powerset PS_NOSCREEN 1
    fuchsctl powerset PS_NONET    1
    fuchsctl scharf
    halt -p & exit

Die ersten beiden Befehle sind optional und davon abhängig, ob das
System später noch im Zugriff bleiben soll (kann aber jederzeit direkt
in der `/boot/fuchsfalle.cfg` zurückgesetzt werden).

Nach dem Herunterfahren des Pi kommt das Verbindungskabel vom PIC
nach dem entfernen des Jumpers wieder in die Bu2. Außerdem sollte jetzt
der UMTS-Stick in den Pi eingesteckt werden.

Auf dem PIC den Reset-Knopf drücken. Ab jetzt läuft die Zeit.

*Für die folgenden Akku-Unterspannungstests muß der Akku aus dem Fach
entfernt werden und die Akkusimulation per SNT und Stepup-Konverter mit
LED-Anzeige der Spannung an Bu1 der Platine PIC-Pi-3 angeschlossen
werden. Der Stepup-Konverter mit LED-Anzeige ist auf ca. 3,8V (zwischen
3,6 und 4,2 V, d.h. keine Unterspannung) einzustellen.*


Test: Falle offen, keine Unterspannung
--------------------------------------

Testklappe so positionieren, dass S1 offen. Ungefähr 8 Minuten warten.

**Erwartetes Ergebnis: der Pi fährt in dieser Zeit nicht hoch.**


Test: Falle zu, keine Unterspannung
-----------------------------------

Testklappe entsprechend positionieren (S1 geschlossen). Warten...

**Erwartetes Ergebnis: der Pi fährt nach ca. 5 Minuten hoch und versendet
eine entsprechende SMS.**

Weitere 10 Minuten warten.

**Erwartetes Ergebnis: der Pi fährt in dieser Zeit nicht hoch.**


Test: Falle offen, Unterspannung
--------------------------------

Testklappe neu positionieren (S1 offen). Reset drücken.
Strom auf Unterspannung setzen, indem der Stepup-Konverter
mit LED auf ca. 3,2V eingestellt wird.

**Erwartetes Ergebnis: der Pi fährt nach ca. 5 Minuten hoch und versendet
eine entsprechende SMS.**

Weitere 10 Minuten warten.

**Erwartetes Ergebnis: der Pi fährt in dieser Zeit nicht hoch.**


Test: Falle zu, Unterspannung
-----------------------------

Testklappe neu positionieren (S1 geschlossen). Reset drücken.

**Erwartetes Ergebnis: der Pi fährt nach ca. 5 Minuten hoch und versendet
eine entsprechende SMS.**

Weitere 10 Minuten warten.

**Erwartetes Ergebnis: der Pi fährt in dieser Zeit nicht hoch.**

