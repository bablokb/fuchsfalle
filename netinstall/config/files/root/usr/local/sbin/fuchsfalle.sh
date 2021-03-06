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

pgm_name=$(basename "$0")
logfile="/var/log/${pgm_name%.*}.log"

# --- Meldung ausgeben   ----------------------------------------------------

msg() {
  if [ -n "$DEBUG" ]; then
    local tstamp="[$(date '+%Y%m%d %H:%M:%S')] "
    (echo -en "$tstamp"; logger -s -t  "$pgm_name" "$1" 2>&1) | tee -a "$logfile"
    sync
  fi
}

# --- Definition/Einlesen von Konstanten   ----------------------------------

read_config() {
  # Return-Codes von gammu
  local grinc="$(dirname "$0")/gammu_retcode.inc"
  if [ -f "$grinc" ]; then
    source "$grinc"
  else
    DEBUG=1 msg "Datei $grinc fehlt!"
    abbruch
  fi
  # Einlesen Konfiguration
  if [ -f "/boot/fuchsfalle.cfg" ]; then
    source "/boot/fuchsfalle.cfg"
  else
    DEBUG=1 msg "Konfiguration /boot/fuchsfalle.cfg fehlt!"
    abbruch
  fi

  # Modem-Name aus /etc/gammurc extrahieren
  MODEM=$(sed -ne '/device/s/.*= //p' /etc/gammurc)
  msg "Modem aus /etc/gammurc: $MODEM"

  # Array mit Meldungstexten
  declare -g -a meldung
  meldung=( \
    "Falle $FNR: Falle zu. Akkuspannung unter 3,3V." \
    "Falle $FNR: Falle zu" \
    "Falle $FNR: Akkuspannung unter 3,3V." \
    "Falle $FNR: Alles in Ordnung (Heartbeat-Meldung)."  )
}

# --- Konfiguration ausgeben   ----------------------------------------------

dump_config() {
  msg "FNR: $FNR"
  msg "SMS_NR: $SMS_NR"
  msg "PIN: $PIN"
  msg "MAX_V: $MAX_V"
  msg "SLEEP_V: $SLEEP_V"
}

# --- Initialisierung   -----------------------------------------------------

init_modem() {
  # Absetzen von udevadm, warten auf das USB-Device
  test -c "$MODEM" || udevadm trigger
  declare -i i=1
  while test "$i" -le "$MAX_V"; do
    if test -c "$MODEM"; then
      msg "Modem-Device $MODEM verfügbar"
      break
    else
      msg "Warte $SLEEP_V Sekunden auf $MODEM"
      sleep "$SLEEP_V"
    fi
    let i+=1
  done

  # Abbruch, falls Modem immer noch nicht verfügbar
  if [ ! -c "$MODEM" ]; then
    msg "Modem-Device $MODEM nicht verfügbar - Abbruch!"
    abbruch
  fi

  # Falls PIN leer, wird sie auch nicht gesetzt
  if [ -z "$PIN" ]; then
    msg "PIN ist leer"
    return
  fi

  # Mehrere Versuche, die PIN zu setzen. Der spezielle Return-Code
  # 114 (Timeout) wird dabei abgefangen, die anderen nicht (die
  # SIM soll durch eine falsche PIN nicht auf die Schnelle gesperrt werden)

  let i=1
  while test "$i" -le "$MAX_V"; do
    gammu entersecuritycode PIN "$PIN"
    local rc="$?"
    if [ "$rc" -eq 0 -o "$rc" -eq 101 ]; then
      msg "PIN erfolgreich gesetzt"
      return
    elif [ "$rc" -eq 123 ]; then
      # Security-Fehler: sofortiger Abbruch, um SIM nicht zu sperren
      msg "Konnte PIN nicht setzen (Code: $rc: ${gammuret[$rc]}) - Abbruch!"
      break
    else
      msg "Konnte PIN nicht setzen (Code: $rc: ${gammuret[$rc]})!"
      msg "Warte $SLEEP_V Sekunden vor einem neuen Versuch"
      sleep "$SLEEP_V"
    fi
    let i+=1
  done

  # hier kommen wir nur im Fehlerfall hin (Abbruch oder zu viele Versuche)
  abbruch
}

# --- Auslesen der GPIOs   --------------------------------------------------

lese_gpios() {
  # Das Unterprogramm gibt den Status der Pins als Zahl aus:
  # niederwertigstes Bit: GPIO17, höherwertiges Bit: GPIO27
 
  local gpio17 gpio27
 
  # Pins verfügbar machen für das Lesen
  gpio -g mode 17 in
  gpio -g mode 27 in

  # Pins auslesen
  gpio17=$(gpio -g read 17)
  gpio27=$(gpio -g read 27)

  # Log schreiben
  msg "Status GPIO17: $gpio17"
  msg "Status GPIO27: $gpio27"

  # Ergebnis berechnen (globale Variable)
  declare -i -g gpio_status
  let gpio_status=gpio17+2*gpio27
  msg "Gesamtstatus: $gpio_status"
}

# --- Meldung verschicken   ------------------------------------------------

sende_sms() {
  # erstes Argument ist die Nummer der Meldung
  local nr="$1" text sms_nr
 
  # Die meldung[3] geht an den Admin (Heartbeat-Meldung)
  if [ "$nr" -eq 3 -a -n "$SMS_ADMIN" ]; then
    sms_nr="$SMS_ADMIN"
  else
    sms_nr="$SMS_NR"
  fi

  # Wir nutzen den Meldungsnummer als Index in den Array
  text="[$(date '+%d.%m.%Y %H:%M:%S')] ${meldung[$nr]}"
  msg "Versende Meldung an $sms_nr: $text"

  # Prüfen auf /boot/nosend (Testmodus)
  if [ -f "/boot/nosend" ]; then
    msg "Testmodus: SMS wird NICHT gesendet!"
    return
  fi

  # Maximal MAX_V Versuche für den Versand der SMS
  local rc
  declare -i i=1
  while test "$i" -le "$MAX_V"; do
    gammu sendsms TEXT "$sms_nr" -text "$text"
    rc="$?"
    if [ "$rc" -eq 0  -o "$rc" -eq 101 ]; then
      msg "Versuch $i: SMS-Versand erfolgreich"
      return
    else
      msg "Versuch $i: Fehler (Code: $rc: ${gammuret[$rc]})"
      sleep "$SLEEP_V"
    fi
    let i+=1
  done

  # hier kommen wir nur im Fehlerfall hin -> Abbruch
  msg "SMS-Versand fehlgeschlagen"
  abbruch
}

# --- GPIO 22 setzen (erstes Argument ist 0 oder 1)   ----------------------

schreibe_gpio22() {
  # Pin 22 verfügbar machen für das schreiben
  if [ ! -d /sys/class/gpio/gpio22/ ]; then
    echo "22"  > /sys/class/gpio/export
    echo "out" > /sys/class/gpio/gpio22/direction
  fi

  # gemäß erstem Argument setzen
  msg "Setze GPIO22 auf $1"
  echo "$1" > /sys/class/gpio/gpio22/value
}

# --- Abbruch mit Fehler   -------------------------------------------------

abbruch() {
  schreibe_gpio22 0
  DEBUG=1 msg "__________ Programmende $pgm_name (mit Fehler) _____________"
  exit 3
}

# --- Hauptprogramm   ------------------------------------------------------

DEBUG=1 msg "__________ Programmstart $pgm_name ___________________________"
DEBUG=1 schreibe_gpio22 1

# --- Konfiguration lesen
read_config
dump_config

# --- Simulation von Fehlern für das Testen der Komponenten
if [ "$ETEST" = "NOSMS" ]; then
  # SMS-Versand schlägt fehl
  msg "Fehlersimulation: SMS-Versand fehlgeschlagen"
  abbruch
elif [ "$ETEST" = "LOOP" ]; then
  # fuchsfalle.sh hängt sich auf (rc.local sollte den Prozess dann beenden)
  msg "Fehlersimulation: $pgm_name hängt sich auf"
  while true; do
    sleep 10
    msg "Fehlersimulation: ..."
  done
fi

# --- eigentliche Verarbeitung
lese_gpios
init_modem
sende_sms "$gpio_status"
DEBUG=1 msg "__________ Programmende $pgm_name (Erfolg) ___________________"
