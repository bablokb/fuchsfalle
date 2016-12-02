Zeit über GSM
=============


Variante GPRS
-------------

AT^SIND=nitz,1

Danach ins GPRS einbuchen. Jetzt wird jedesmal beim Einbuchen ins Netz
mit AT+CGATT=1 der Zeitstempel aktualisiert.
+CIEV: nitz, "08/12/11,09:02:17",+04,0

Nachtteil:
Diese Variante funktioniert nicht bei allen Modulen und auch nicht bei 
allen Anbietern. Kostenpflichtig je nach Anbieter.



Variante SMS
------------

AT+CMGF=1
AT+CSMP=1,"yy/MM/dd,hh:mm:ss+zz",0,0
AT+CNMI=2,2,0,1,1

Wenn jetzt eine SMS mittels AT+CMGS verschickt wird, dann bekomme man 
beim Senden und beim Empfangen einen Zeitstempel.

Zusätzlich kann man noch die Zeit zwischen Senden und Empfangen der SMS 
messen. Dadurch erhält man noch den Roundtrip Delay, welchen man zur 
Korrektur verwenden kann.


Nachteil:
Zeit ist nicht sehr genau. Gewisse Delays können sich ein schleichen.
Kostenpflichtig.

Vorteil:
Geht mit jedem Modul und mit jedem Betreiber.


Variante AT
-----------

AT+CCLK?

(liest eventuell nur die Modem-interne RTC).