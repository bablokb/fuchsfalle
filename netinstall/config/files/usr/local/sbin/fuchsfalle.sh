#!/bin/bash
# ---------------------------------------------------------------------------
#
# Das Skript fragt die GPIO-Pins 17 und 27 ab. Je nach Zustand versendet
# das Skript einen anderen Text per SMS.
#
# Das Skript läuft automatisch beim Systemstart aus der /etc/rc.local.
# Dort wird es überwacht und zur Not abgeschossen. Nach dem Ende
# des Skripts (so oder so) fährt das System wieder herunter.
#
# Es gibt einen Testmodus: falls die Datei /boot/nosend existiert, dann
# wird keine SMS versendet.
#
# Autor: Bernhard Bablok
# Lizenz: GPL3
#
# Website: https://github.com/bablokb/fuchsfalle
#
# ---------------------------------------------------------------------------

# --- Definition von Konstanten   -------------------------------------------

MODEM="/dev/ttyUSB2"
FNR="4"                # Nummer der Falle
SMS_NR="123456789"     # SMS-Nummer
PIN="1234"             # PIN-Nummer
MAX_V="10"             # Anzahl Versuche in Schleifen
SLEEP_V="3"            # Sekunden zwischen den Versuchen
declare -a meldung     # Array mit Meldungstexten

meldung=( \
  "Falle $FNR: Akkuspannung unter 3,3V." \
  "Falle $FNR: Falle zu" \
  "Falle $FNR: Falle zu. Akkuspannung unter 3,3V." \
  "Falle $FNR: Alles in Ordnung, aber Pi unnötig aufgeweckt."  )

# --- Initialisierung   -----------------------------------------------------

init_modem() {
  # Absetzen von udevadm, warten auf das USB-Device
  test -c "$MODEM" || udevadm trigger
  local i
  let i=1
  while test i -le $MAX_V; do
    if test -c "$MODEM"; do
      logger -s -t  "$pgm_name" "Modem-Device $MODEM verfügbar"
      break
    else
      logger -s -t  "$pgm_name" "Warte $SLEEP_V Sekunden auf $MODEM"
      sleep "$SLEEP_V"
    fi
    let i+=1
  done

  # Abbruch, falls Modem immer noch nicht verfügbar
  test -c "$MODEM" || exit 3

  # Setzen der PIN
  gammu entersecuritycode PIN - <<< $PIN
  local rc="$?"
  if [ "$rc" -eq 0 ]; then
    logger -s -t "$pgm_name" "PIN erfolgreich gesetzt"
    return
  else
    logger -s -t "$pgm_name" "Konnte PIN nicht setzen (Code: $rc)"
    exit 3
  fi  
}

# --- Auslesen der GPIOs   --------------------------------------------------

lese_gpios() {
  # Das Unterprogramm gibt den Status der Pins als Zahl aus:
  # niederwertigstes Bit: GPIO17, höherwertiges Bit: GPIO27
 
  local gpio17 gpio27
 
  # Pins verfügbar machen für das Lesen
  echo "17" > /sys/class/gpio/export
  echo "in" > /sys/class/gpio/gpio17/direction
  echo "27" > /sys/class/gpio/export
  echo "in" > /sys/class/gpio/gpio27/direction

  # Pins auslesen
  gpio17=$(cat /sys/class/gpio/gpio17/value)
  gpio27=$(cat /sys/class/gpio/gpio27/value)

  # Log schreiben
  logger -s -t "$pgm_name" "Status GPIO17: $gpio17"
  logger -s -t "$pgm_name" "Status GPIO27: $gpio27"

  # Ergebnis berechnen (globale Variable)
  declare -i -g gpio_status
  let gpio_status=gpio17+2*gpio27
  logger -s -t "$pgm_name" "Gesamtstatus: $gpio_status"
}

# --- Meldung verschicken   ------------------------------------------------

sende_sms() {
  # erstes Argument ist die Nummer der Meldung
  local nr="$1" text
 
  # Wir nutzen den Meldungsnummer als Index in den Array
  text="${meldung[$nr]}"
  logger -s -t "$pgm_name" "Versende Meldung: $text"

  # Prüfen auf /boot/nosend (Testmodus)
  if [ -f "/boot/nosend" ]; then
    logger -s -t "$pgm_name" "Testmodus: SMS wird NICHT gesendet!"
    return
  fi

  # Maximal MAX_V Versuche für den Versand der SMS
  local i rc
  let i=1
  while test i -le $MAX_V; do
    gammu sendsms TEXT "$SMS_NR" -text "$text"
    rc="$?"
    if [ "$rc" -eq 0 ]; then
      logger -s -t "$pgm_name" "Versuch $i: SMS-Versand erfolgreich"
      return
    else
      logger -s -t "$pgm_name" "Versuch $i: Fehler (Code: $rc)"
      sleep "$SLEEP_V"
    fi
    let i+=1
  done

  # hier kommen wir nur im Fehlerfall hin -> Abbruch
  logger -s -t "$pgm_name" "SMS-Versand fehlgeschlagen"
  exit 3
}

# --- GPIO 22 auf Low setzen   ---------------------------------------------

schreibe_gpio() {
  # Pin 22 verfügbar machen für das schreiben
  echo "22"  > /sys/class/gpio/export
  echo "out" > /sys/class/gpio/gpio22/direction

  # auf Low setzen
  echo "0" > /sys/class/gpio/gpio22/value
}

# --- Hauptprogramm   ------------------------------------------------------

pgm_name=$(basename "$0")
init_modem                 2>&1 | tee "/var/log/$pgm_name.log"
lese_gpios                 2>&1 | tee "/var/log/$pgm_name.log"
sende_sms "$gpio_status"   2>&1 | tee "/var/log/$pgm_name.log"

# Im Fehlerfall bricht sende_sms ab, hier schreiben wir den Erfolg
# nach GPIO22 (low)
schreibe_gpio              2>&1 | tee "/var/log/$pgm_name.log"