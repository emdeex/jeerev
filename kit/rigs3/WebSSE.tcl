Jm doc "Support for web Server-Sent Events."
# see also http://dev.w3.org/html5/eventsource/
Webserver hasUrlHandlers

Ju cachedVar listeners - {
  variable listeners ""
}

proc /events/**: {type} {
  wibble sendresponse [list sendcommand [list [namespace which MySend] $type]]
}

proc MySend {type sock request response} {
  # Custom send command which sets up a permanent socket for SSE's.
  variable listeners
  chan configure $sock -buffering none
  chan puts $sock "HTTP/1.1 200 OK\nContent-Type: text/event-stream\n"
  Log websse {$sock connected ($type)}
  if {![dict exists $listeners $type]} {
    app hook WEBSSE.OPEN $type
  }
  dict lappend listeners $type $sock
  wibble cleanup websse [list [namespace which OnClose] $type $sock]
  return 1 ;# keep the socket open
}

proc OnClose {type sock} {
  variable listeners
  Log websse {$sock closed ($type)}
  set sockets [Ju omit [dict get $listeners $type] $sock]
  if {[llength $sockets] > 0} {
    dict set listeners $type $sockets
  } else {
    dict unset listeners $type
    app hook WEBSSE.CLOSE $type
  }
}

proc propagate {type args} {
  variable listeners
  set msg "data:[join [split [Ju toJson $args -map] \n] \ndata:]\n"
  foreach sock [dict get? $listeners $type] {
    puts $sock $msg
  }  
}
