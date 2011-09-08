Jm doc "Replay some stored data to simplify development."
Jm autoLoader ./drivers

proc APP.READY {} {
  variable readings {}
  # get some additional interface configuration info for fake insertions
  variable config [Ju unComment [Ju readFile [Ju mySourceDir]/rconfig.txt]]
  # collect all the stored readings into a sorted list
  source [Ju mySourceDir]/logall.txt
  Log replay {[llength $readings] readings}
  # play back this data at exactly the same time as logged, but on any day
  after idle [namespace which Playback]
}

proc L {time dev args} {
  # the "logall.txt" file is a set of L cmds, so sourcing it will end up here
  variable readings
  # deal with old (0.9) and new style calls (which only pass one arg with text)
  if {[llength $args] == 1 && [string is list [lindex $args 0]]} {
    set args [lindex $args 0]
  }
  if {[lindex $args 0] ne "?"} {
    lassign [split $time .] secs msecs
    set scantime [clock scan $secs -gmt 1]
    set millis [+ [* [% $scantime 86400] 1000] [scan $msecs %d]]
    # set millis [expr {($scantime % 86400) * 1000 + [scan $msecs %d]}]
    lappend readings [list $millis $dev $args]
  }
}

Ju cachedVar interfaces -once {
  variable interfaces {}
  # set up the device information, this should match what's in the log file
  variable config
  set devs [dict get $config devices:]
  dict for {k v} $devs {
    Jm needs $v
    Driver register $k $v
  }
  Log replay {[dict size $devs] devices defined}
}

proc Playback {} {
  variable config
  variable readings
  variable interfaces
  set now [clock milliseconds]
  # current time of day in milliseconds, relative to midnight GMT
  set tod [% $now 86400000]
  set pos [lsearch -bisect -integer -index 0 $readings $tod]
  set next [lindex $readings $pos+1 0]
  if {$next eq ""} {
    set next [lindex $readings 0 0] ;# wrap around to reuse next day
  }
  # schedule the next playback event
  set ms [% [- $next [clock milliseconds]] 86400000]
  after $ms [namespace which Playback]
  # Log replay {<[string range [lindex $readings $pos] 0 30]...> wait $ms}
  lassign [lindex $readings $pos] - dev msg
  dict set data when [/ $now 1000]
  dict set data source replay
  # generate a fake interface insertion the first time data comes in for it
  if {$dev ni $interfaces} {
    lappend interfaces $dev
    set prefix [dict get? $config startup: $dev]
    if {$prefix ne ""} {
      Driver dispatch $dev message $prefix
    }
  }
  # report this as if it were a new reading which just came in
  Driver dispatch $dev message $msg when [/ $now 1000] source replay
}
