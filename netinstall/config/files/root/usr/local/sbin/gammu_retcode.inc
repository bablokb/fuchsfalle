# ---------------------------------------------------------------------------
# Returncodes von gammu.
#
# Diese Datei wird von fuchsfalle.sh eingelesen und der Text zu den
# Fehlercodes in den Logmeldungen ausgegeben.
#
# Autor: Bernhard Bablok
# Lizenz: GPL3
#
# Website: https://github.com/bablokb/fuchsfalle
#
# ---------------------------------------------------------------------------

declare -g -A gammuret
gammuret=( \
  [1]="Out of memory or other critical error" \
  [2]="Invalid command line parameters" \
  [3]="Failed to open file specified on command line" \
  [4]="Program was interrupted" \
  [98]="Gammu library version mismatch" \
  [99]="Functionality has been moved. For example to gammu-smsd" \
  [101]="No error" \
  [102]="Error opening device. Unknown, busy or no permissions" \
  [103]="Error opening device, it is locked" \
  [104]="Error opening device, it doesn’t exist" \
  [105]="Error opening device, it is already opened by other application" \
  [106]="Error opening device, you don’t have permissions" \
  [107]="Error opening device. No required driver in operating system" \
  [108]="Error opening device. Some hardware not connected/wrongly configured" \
  [109]="Error setting device DTR or RTS" \
  [110]="Error setting device speed. Maybe speed not supported" \
  [111]="Error writing to the device" \
  [112]="Error during reading from the device" \
  [113]="Can’t set parity on the device" \
  [114]="No response in specified timeout. Probably phone not connected" \
  [115]="Frame not requested right now. See <https://wammu.eu/support/bugs/> for information how to report it" \
  [116]="Unknown response from phone. See <https://wammu.eu/support/bugs/> for information how to report it" \
  [117]="Unknown frame. See <https://wammu.eu/support/bugs/> for information how to report it" \
  [118]="Unknown connection type string. Check config file" \
  [119]="Unknown model type string. Check config file" \
  [120]="Some functions not available for your system (disabled in config or not implemented)" \
  [121]="Function not supported by phone" \
  [122]="Entry is empty" \
  [123]="Security error. Maybe no PIN" \
  [124]="Invalid location. Maybe too high" \
  [125]="Functionality not implemented. You are welcome to help authors with it" \
  [126]="Memory full" \
  [127]="Unknown error" \
  [128]="Can not open specified file" \
  [129]="More memory required.." \
  [130]="Operation not allowed by phone" \
  [131]="No SMSC number given. Provide it manually or use the one configured in phone" \
  [132]="You’re inside phone menu (maybe editing?). Leave it and try again" \
  [133]="Phone is not connected" \
  [134]="Function is currently being implemented. If you want to help, please contact authors" \
  [135]="Phone is disabled and connected to charger" \
  [136]="File format not supported by Gammu" \
  [137]="Nobody is perfect, some bug appeared in protocol implementation. Please contact authors" \
  [138]="Transfer was canceled by phone, maybe you pressed cancel on phone" \
  [139]="Phone module need to send another answer frame" \
  [140]="Current connection type doesn’t support called function" \
  [141]="CRC error" \
  [142]="Invalid date or time specified" \
  [143]="Phone memory error, maybe it is read only" \
  [144]="Invalid data given to phone" \
  [145]="File with specified name already exists" \
  [146]="File with specified name doesn’t exist" \
  [147]="You have to give folder name and not file name" \
  [148]="You have to give file name and not folder name" \
  [149]="Can not access SIM card" \
  [150]="Wrong GNAPPLET version in phone. Use version from currently used Gammu" \
  [151]="Only part of folder has been listed" \
  [152]="Folder must be empty" \
  [153]="Data were converted" \
  [154]="Gammu is not configured" \
  [155]="Wrong folder used" \
  [156]="Internal phone error" \
  [157]="Error writing file to disk" \
  [158]="No such section exists" \
  [159]="Using default values" \
  [160]="Corrupted data returned by phone" \
  [161]="Bad feature string in configuration" \
  [162]="Desired functionality has been disabled on compile time" \
  [163]="Bluetooth configuration requires channel option" \
  [164]="Service is not running" \
  [165]="Service configuration is missing" \
  [166]="Command rejected because device was busy. Wait and restart" \
  [167]="Could not connect to the server" \
  [168]="Could not resolve the host name" \
  [169]="Failed to get SMSC number from phone" \
  [170]="Operation aborted" \
  [171]="Installation data not found, please consult debug log and/or documentation for more details" \
  [172]="Entry is read only." \
)
