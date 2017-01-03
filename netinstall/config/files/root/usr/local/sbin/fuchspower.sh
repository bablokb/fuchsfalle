#!/bin/bash
# ---------------------------------------------------------------------------
#
# Das Skript führt gesteuert durch fuchsfalle.cfg verschiedene Kommandos aus,
# die den Stromverbrauch minimieren.
#
# Das Skript läuft automatisch beim Systemstart (gestartet durch Systemd).
# Es kann auch manuell für das Ein- oder Ausschalten des Stromsparmodus
# genutzt werden, in diesem Fall erwartet es einen Parameter: "an" oder "aus".
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
  # Einlesen Konfiguration
  if [ -f "/boot/fuchsfalle.cfg" ]; then
    source "/boot/fuchsfalle.cfg"
  else
    DEBUG=1 msg "Konfiguration /boot/fuchsfalle.cfg fehlt!"
    abbruch
  fi
}

# --- Konfiguration ausgeben   ----------------------------------------------

dump_config() {
  msg "PS_NOSCREEN: $PS_NOSCREEN"
  msg "PS_NOLED:    $PS_NOLED"
  msg "PS_NONET:    $PS_NONET"
  msg "PS_NOWLAN:   $PS_NOWLAN"
  msg "PS_NOBT:     $PS_NOBT"
}

# --- Abbruch mit Fehler   -------------------------------------------------

abbruch() {
  DEBUG=1 msg "__________ Programmende $pgm_name (mit Fehler) _____________"
  exit 3
}

# --- System konfigurieren   -----------------------------------------------

config_system() {
  local tstate="$1"
  if [ -z "$tstate" ]; then
    msg "Kein Argument angegeben"
    abbruch
  fi

  tstate="${tstate,,}"              # Kleinbuchstaben sicherstellen
  if [ "$tstate" != "an" -a "$tstate" != "aus" ]; then
    msg "Falsches Argument $1. Zulässig sind 'an' oder 'aus'"
    abbruch
  fi

  if [ "$tstate" = "an" ]; then
    msg "Aktiviere Stromsparmechanismen"
    [ "$PS_NOSCREEN" -eq 1 ] && /opt/vc/bin/tvservice -o
                               # vcgencmd display_power 0
    [ "$PS_NOLED"    -eq 1 ] && echo "none" > /sys/class/leds/led0/trigger
    [ "$PS_NONET"    -eq 1 ] && systemctl stop networking.service
    [ "$PS_NOWLAN"   -eq 1 ] && rfkill block wifi
    [ "$PS_NOBT"     -eq 1 ] && rfkill block bluetooth
  elif [ "$(systemctl is-system-running)" != "stopping" ]; then
    msg "Deaktiviere Stromsparmechanismen"
    [ "$PS_NOSCREEN" -eq 1 ] && /opt/vc/bin/tvservice -p
                                 # vcgencmd display_power 1
    [ "$PS_NOLED"    -eq 1 ] && echo "mmc0" > /sys/class/leds/led0/trigger
    [ "$PS_NONET"    -eq 1 ] && systemctl start networking.service
    [ "$PS_NOWLAN"   -eq 1 ] && rfkill unblock wifi
    [ "$PS_NOBT"     -eq 1 ] && rfkill unblock bluetooth
  else
    msg "System fährt runter, keine Aktion notwendig"
  fi
}

# --- Hauptprogramm   ------------------------------------------------------

DEBUG=1 msg "__________ Programmstart $pgm_name ___________________________"

# --- Konfiguration lesen
read_config
dump_config

# --- eigentliche Verarbeitung
config_system "$1"
DEBUG=1 msg "__________ Programmende $pgm_name (Erfolg) ___________________"
