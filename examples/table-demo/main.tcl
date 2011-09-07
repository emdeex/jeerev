Jm doc "Show readings as table in a browser with real-time updates."
Jm needs WebSSE
Webserver hasUrlHandlers

if {[app get -collectd 0]} {  
  variable pattern sysinfo:*
  collectd listen sysinfo
} else {
  variable pattern reading:*
  Jm needs Replay

  Driver locations {
    usb-USB0       house         
    usb-ACM0       office        
    usb-A600dVPp   office        

    RF12-868.5.2   jc-books      
    RF12-868.5.3   lipotest      
    RF12-868.5.4   guest-room
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
    S300-2         balcony
    EM2-8          lab-outlet
  }
}

proc /: {} {
  # Respond to "/" url requests.
  set html [Ju readFile [Ju mySourceDir]/page.tmpl]
  wibble pageResponse html [wibble template $html]
}

proc /data.json: {} {
  # Returns a JSON-formatted array with all current values.
  variable pending
  variable pattern
  # The trick is to simulate a change on each state variable and then
  # collect those "pending changes" instead of sending them off as SSE's.
  Propagate ;# flush pending events now, since we're going to clobber $pending
  Ju map TrackState [State keys $pattern]
  wibble pageResponse json [Propagate -collect]
}

proc WEBSSE.SESSION {mode type} {
  # Respond to WebSSE hook events when a session is opened or closed.
  variable pattern
  if {$type eq "table"} {
    set cmd [string map {open subscribe close unsubscribe} $mode]
    State $cmd $pattern [namespace which TrackState]
  }
}

proc TrackState {param} {
  # Add a result to the pending map for the specified state variable.
  # Will also set up a timer if needed, to flush these results shortly.
  set value [State get $param]
  set fields [split $param :]
  if {[llength $fields] >= 5} {
    # for collectd, simply remove one of the segments and clean up the value
    if {[llength $fields] == 6} {
       regsub {(.*) } $fields {\1-} fields 
    }
    set fields [lreplace $fields 2 2]
    if {[string is double -strict $value] && [round $value] ne $value} {
      set value [format %.5g $value]
    }
  }
  if {[llength $fields] == 4} {
    lassign $fields - where driver what
    dict extract [Driver getInfo $driver $where $what] \
      desc scale location unit low high
    if {$location eq ""} {
      set location $where
    }
    if {$desc eq ""} {
      set desc "$what ($driver)"
    }
    if {$unit eq "" && $low ne "" && $high ne ""} {
      set unit "$low..$high"
    }
    set scaled [Driver scaledInt $value $scale]
    dict extract [State getInfo $param] m t
    set item [list $scaled $unit [ShortTime $m] [ShortTime $t]]
    # batch multiple changes into one before propagating them as SSE's
    variable pending
    if {![info exists pending]} {
      after 100 [namespace which Propagate]
    }
    dict set pending "$location $desc" [Ju toJson $item -list]
  }
}

proc ShortTime {secs} {
  if {$secs > 0} {
    set fmt {%H:%M:%S}
    if {$secs < [clock scan 0:00]} {
      set fmt {%b %e}
    }
    clock format $secs -format $fmt
  }
}

proc Propagate {{flag ""}} {
  # Send pending changes off as a JSON object and clear the list.
  variable pending
  set json [Ju toJson [Ju grab pending] -dict -flat]
  if {$flag eq "-collect"} {
    return $json
  }
  WebSSE propagate table $json
}
