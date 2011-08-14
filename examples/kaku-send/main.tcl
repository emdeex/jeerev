Jm doc "Send a command to the KlikAanKlikUit remote control."

Webserver hasUrlHandlers

proc APP.READY {} {
  # Called once during application startup.

  # create a connection object
  set device [Config connect:device usb-A700fdxv]
  variable conn [Serial connect $device 57600]
}

proc /: {} {
  # Respond to "/" url requests.
  set html [Ju readFile [Ju mySourceDir]/page.tmpl]
  dict set response content [wibble template $html]
}

proc /do/*/*/*: {device group house} {
  # Respond to KAKU on/off requests.
  variable conn
  # decode house codes A..P to 1..16
  scan $house %c h
  if {$h eq ""} { set h 1 }
  set h [expr {($h-1) % 16 + 1}]
  # combine groups I/II/III/IV and devices 1..4 into 1..64
  set g [dict get {I 0 II 1 III 2 IV 3} $group]
  set d [expr {4 * $g + [string index $device end]}]
  # construct command string to send to the RF12demo sketch
  set cmd "$h,$d,[string match on* $device]k"
  # Log the command and send it
  Log kaku {$house $group $device : $cmd}
  $conn send $cmd
}
