Tests mit der Testplatine
=========================

Alle Testfälle gehen davon aus, dass der Pi aus dem Status "stromlos"
gestartet wird.

  1. Fall (AKTIV=`0`)

  Bei `AKTIV=0` fährt das System hoch, setzt GPIO22 auf low und bleibt
  hochgefahren, d.h. es wird erst gar nicht versucht, eine SMS zu senden
  aber an der Testplatine sieht man das "Ergebnis".

  2. Fall (AKTIV=`1`)

  In diesem Fall sucht der Pi nach dem Modem, setzt dort die Pin und
  simuliert den Versand der richtigen Meldung (je nach Konfiguration
  der Testplatine). Anschließend setzt er alle GPIOs, fährt aber nicht
  runter. Die Testplatine sollte den richtigen Status zeigen. Im
  Systemlog stehen die Meldungen:

  `sudo journalctl SYSLOG_IDENTIFIER=rc.local`
  `sudo journalctl SYSLOG_IDENTIFIER=fuchsfalle.sh`

  oder mit (nur Meldungen von fuchsfalle.sh):

  `sudo less /var/log/fuchsfalle.log`

  3. Fall (AKTIV=`1`, Datei `/boot/nosend` gelöscht/umbenannt)

  Existiert die Datei `/boot/nosend` nicht, so passiert dasselbe
  wie im 2.Fall mit dem einzigen Unterschied, dass der Pi tatsächlich
  die SMS verschickt. Wenn man sicher ist, dass der SMS-Versand klappt,
  dann kann man die Datei `/boot/nosend` wieder herstellen per
  `sudo touch /boot/nosend`, das spart dann bei den weiteren Tests die
  SMS-Kosten.

  4. Fall (wie 3.Fall aber zusätzlich ohne Datei `/boot/nohalt`)

  Das ist das eigentliche Produktivszenario: die SMS wird verschickt
  und der Pi fährt wieder runter.

  Wenn etwas nicht so funktioniert hat wie man möchte, dann muss man sich
  die Logs ansehen.

  An die Logs kommt man jetzt aber etwas schwieriger ran, weil der Pi ja
  wieder sofort runterfährt. Entweder man entnimmt die Karte und ändert
  wahlweise AKTIV=0 oder erstellt wieder die /boot/nohalt (das müsste
  sogar auf einem Windows-PC gehen). Beim nächsten Start bleibt der Pi
  wieder oben und man kann sich die Logs ansehen.

  5. Fall und Folgende

  Das sind alles Variationen, z.B. durch ändern der
  Einstellung der Testplatine. Fehlersituationen kööen über die
  ETEST-Variable in der `/boot/fuchsfalle.cfg` simuliert werden.
