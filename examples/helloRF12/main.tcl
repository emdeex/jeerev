Jm doc "Collect and display data from a JeeNode running RF12demo."

# This is a very basic demo, which just shows the last 25 received packets as
# a plain text page. No formatting, just enough for testing or web-scraping.

Jm needs Webserver

proc APP.READY {} {
  # Called once during application startup.
  set device [Config connect:device usb-A700fdxv]

  # create a connection object
  set conn [Serial connect $device 57600]

  # wait for startup, then reconfigure the JeeNode as specified
  after 1000 [list $conn send [Config connect:config "8b 5g 1i"]]
  
  # adjust the connection to pick up and save the last 25 incoming messages
  variable history {}
  
  #TODO - This approach of "overriding a method in a connection object" is too
  # complicated and exposes more complexity than needed. Should be simplified!

  objdefine $conn method onReceive {msg} {
    my variable seqnum
    namespace upvar ::main history history
    
    if {[string match "OK *" $msg]} {
      lappend history "#[incr seqnum] [Log now] - $msg"
      set history [lrange $history end-24 end]
    } else {
      next $msg ;# log unrecognized messages
    }
  }
}

proc WEBSERVER.PATHS {} {
  # Return the list of commands which repond to specific URLs.
  info commands /*:
}

proc /: {} {
  # Respond to "/" url requests.
  variable history
  dict set response header content-type {"" text/plain charset utf-8}
  dict set response header refresh 10 
  dict set response content [join $history \n]
}
