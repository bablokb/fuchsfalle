#!/bin/bash
# ---------------------------------------------------------------------------
#
# Hilfsprogramm für das Aktivieren/Deaktivieren der verschiedenen Optionen.
#
# Autor: Bernhard Bablok
# Lizenz: GPL3
#
# Website: https://github.com/bablokb/fuchsfalle
#
# ---------------------------------------------------------------------------

do_help() {
cat <<EOF
Mögliche Parameter:

help  - diese Hilfe
aktiv - Konfiguration AKTIV=1 setzen
inaktiv - Konfiguration AKTIV=0 setzen
send    - Senden von SMS aktivieren
nosend  - Senden von SMS deaktivieren
halt    - Herunterfahren aktivieren
nohalt  - Herunterfahren deaktivieren
sharf   - Scharfschalten des Pi (entspricht "aktiv send halt")
EOF

exit 0
}

# --- -----------------------------------------------------------------------

do_aktiv() {
  sed -i -e '/AKTIV/s/AKTIV="."/AKTIV="1"/' /boot/fuchsfalle.cfg
}

# --- -----------------------------------------------------------------------

do_inaktiv() {
  sed -i -e '/AKTIV/s/AKTIV="."/AKTIV="0"/' /boot/fuchsfalle.cfg
}

# --- -----------------------------------------------------------------------

do_nosend() {
  touch /boot/nosend
}

# --- -----------------------------------------------------------------------

do_send() {
  rm -f /boot/nosend
}

# --- -----------------------------------------------------------------------

do_nohalt() {
  touch /boot/nohalt
}

# --- -----------------------------------------------------------------------

do_halt() {
  rm -f /boot/nohalt
}

# --- -----------------------------------------------------------------------

do_scharf() {
  do_aktiv
  do_send
  do_halt
}

# --- Hauptprogramm   -------------------------------------------------------

if [ -z "$1" ]; then
  do_help
fi

for task in "$@"; do
  eval do_$task
done
