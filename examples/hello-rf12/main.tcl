Jm doc "Collect and display data from a JeeNode running RF12demo."
Webserver hasUrlHandlers

# This is a very basic demo, showing the last 25 received packets as plain text.
# No formatting, no HTML, but enough for a quick test or for web-scraping.

proc APP.READY {} {
  # Called once during application startup.
  variable seqnum
  variable history {}

  # create a connection object
  set device [Config connect:device usb-A700fdxv]
  set conn [Serial connect $device 57600]

  # wait 1 sec for startup, then configure the JeeNode as specified
  after 1000 [list $conn send [Config connect:config "8b 5g 1i"]]
  
  # update the history of the last 25 messages as each one comes in
  $conn onMessage msg {
    if {[string match "OK *" $msg]} {
      lappend history "#[incr seqnum] [Log now] - $msg"
      set history [lrange $history end-24 end]
    } else {
      Log rf12? {$msg}
    }
  }
}

proc /: {} {
  # Respond to "/" url requests.
  variable history
  dict set response header content-type {"" text/plain charset utf-8}
  dict set response header refresh 10 
  dict set response content [join $history \n]
  # wibble pageResponse text [join $history \n]
}
