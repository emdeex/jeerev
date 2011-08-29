Jm doc "Show readings as table in a browser with real-time updates."
Jm needs WebSSE
Webserver hasUrlHandlers

Driver locations {
  usb-USB0       house         
  usb-ACM0       office        
  usb-A600dVPp   office        
                                
  RF12-868.5.2   jc-books      
  RF12-868.5.3   lipotest      
  RF12-868.5.5   living-room    
  RF12-868.5.6   jc-desk       
  RF12-868.5.7   desk
  RF12-868.5.19  lab-bench     
  RF12-868.5.20  lab-bench     
  RF12-868.5.21  lab-bench     
  RF12-868.5.23  upstairs-hall 
  RF12-868.5.24  upstairs-myra 
                  
  KS300          roof
  S300-0         terrace
  S300-1         bathroom
  EM2-8          lab-outlet
}

proc APP.READY {} {
  # Called once during application startup.
  Replay go
}

proc /: {} {
  # Respond to "/" url requests.
  set html [Ju readFile [Ju mySourceDir]/page.tmpl]
  dict set response content [wibble template $html]
}

proc WEBSSE.OPEN {type} {
  if {$type eq "table"} {
    State subscribe reading:* [namespace which TrackState]
  }
}

proc WEBSSE.CLOSE {type} {
  if {$type eq "table"} {
    State unsubscribe reading:* [namespace which TrackState]
  }
}

proc TrackState {param} {
  variable pending
  set fields [split $param :]
  set value [State get $param]
  if {[llength $fields] == 4} {
    lassign $fields - where driver what
    dict extract [Driver getInfo $driver $where $what] desc scale location unit
    if {$location eq ""} {
      set location $where
    }
    if {$desc eq ""} {
      set desc "$what ($driver)"
    }
    dict extract [State getInfo $param] p m
    # collect multiple changes into one before propagating them as SSE's
    if {![info exists pending]} {
      after 100 [namespace which Propagate]
    }
    set data [list "$location $desc" [Driver scaledInt $value $scale] $unit]
    lappend data [clock format $m -format {%H:%M:%S}]
    lappend data [clock format $p -format {%H:%M:%S}]
    dict set pending $param [Ju toJson $data -list]
  }
}

proc Propagate {} {
  variable pending
  WebSSE propagate table "\[[join [dict values $pending] ,]]"
  unset pending
}
