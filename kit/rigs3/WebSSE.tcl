Jm doc "Support for web Server-Sent Events."
# see also http://dev.w3.org/html5/eventsource/
Webserver hasUrlHandlers

proc /events/*: {type} {
  wibble sendresponse [list sendcommand [list [namespace which MySend] $type]]
}

proc MySend {type sock request response} {
  # Custom send command which sets up a permanent socket for SSE's.
  variable listeners
  puts $sock "HTTP/1.1 200 OK\nContent-Type: text/event-stream\n"
  flush $sock
  Log websse {$sock connected ($type)}
  dict lappend listeners $type $sock
  return 1 ;# keeps the socket open
}

proc propagate {type msg} {
  variable listeners
  set msg "data:[join [split $msg \n] \ndata:]\n"
  foreach sock [dict get? [Ju get listeners] $type] {
    try {
      puts $sock $msg
      flush $sock
    } on error {} {
      Log websse {$sock lost connection ($type)}
      catch { close $sock }
      set sockets [lsearch -all -inline -not [dict get $listeners $type] $sock]
      if {[llength $sockets] > 0} {
        dict set listeners $type $sockets
      } else {
        dict unset listeners $type
      }
    }
  }  
}