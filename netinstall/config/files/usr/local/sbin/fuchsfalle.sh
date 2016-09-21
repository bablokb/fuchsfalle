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
  [ -n "$DEBUG" ] && logger -s -t  "$pgm_name" "$1" 2>&1 | tee -a "$logfile"
}

# --- Definition/Einlesen von Konstanten   ----------------------------------

read_config() {
  # Einlesen Konfiguration
  if [ -f "/boot/fuchsfalle.cfg" ]; then
    source "/boot/fuchsfalle.cfg"
  else
    msg "Konfiguration /boot/fuchsfalle.cfg fehlt!"
    exit 3
  fi

  # Modem-Name aus /etc/gammurc extrahieren
  MODEM=$(sed -ne '/device/s/.*= //p' /etc/gammurc)
  msg "Modem aus /etc/gammurc: $MODEM"

  # Array mit Meldungstexten
  declare -g -a meldung
  meldung=( \
    "Falle $FNR: Akkuspannung unter 3,3V." \
    "Falle $FNR: Falle zu" \
    "Falle $FNR: Falle zu. Akkuspannung unter 3,3V." \
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
    exit 3
  fi

  # Setzen der PIN falls nicht leer
  if [ -z "$PIN" ]; then
    msg "PIN ist leer"
    return
  fi
  gammu entersecuritycode PIN "$PIN"
  local rc="$?"
  if [ "$rc" -eq 0 ]; then
    msg "PIN erfolgreich gesetzt"
    return
  else
    msg "Konnte PIN nicht setzen (Code: $rc) - Abbruch!"
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
  if [ "$nr" -eq 3 -a -n "$SMS_ADMIN"]; then
    sms_nr="$SMS_ADMIN"
  else
    sms_nr="$SMS_NR"
  fi

  # Wir nutzen den Meldungsnummer als Index in den Array
  text="${meldung[$nr]}"
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
    if [ "$rc" -eq 0 ]; then
      msg "Versuch $i: SMS-Versand erfolgreich"
      return
    else
      msg "Versuch $i: Fehler (Code: $rc)"
      sleep "$SLEEP_V"
    fi
    let i+=1
  done

  # hier kommen wir nur im Fehlerfall hin -> Abbruch
  msg "SMS-Versand fehlgeschlagen"
  exit 3
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

# --- Hauptprogramm   ------------------------------------------------------

msg "#############  Programmstart  ###########"

# --- Konfiguration lesen
read_config
dump_config

# --- Simulation von Fehlern für das Testen der Komponenten
if [ "$ETEST" = "NOSMS" ]; then
  # SMS-Versand schlägt fehl
  msg "Fehlersimulation: SMS-Versand fehlgeschlagen"
  exit 3
elif [ "$ETEST" = "LOOP" ]; then
  # fuchsfalle.sh hängt sich auf (rc.local sollte den Prozess dann beenden)
  msg "Fehlersimulation: $pgm_name hängt sich auf"
  while true; do
    sleep 10
    msg "Fehlersimulation: ..."
  done
fi

# --- eigentliche Verarbeitung
schreibe_gpio22 1
init_modem
lese_gpios
sende_sms "$gpio_status"

# Im Fehlerfall bricht sende_sms ab, hier schreiben wir den Erfolg
# nach GPIO22 (low)
schreibe_gpio22 0
