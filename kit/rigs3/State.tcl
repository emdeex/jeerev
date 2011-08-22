Jm doc "Manage state variables."

variable state
variable shadow
variable traces
variable patterns

if {![info exists patterns]} {
  array set state {}
  array set shadow {}
  array set traces {}
  set patterns {}
  trace add variable shadow write [namespace which Tracer]
}

proc Tracer {ar el op} {
  variable shadow
  variable traces
  variable patterns
  foreach pat $patterns {
    if {[string match $pat $el]} {
      set d $shadow($el)
      foreach cmd $traces($pat) {
        uplevel [list {*}$cmd $el $d]
      }
    }
  }
}

proc keys {{pattern *}} {
  variable state
  lsort [array names state $pattern]
}

proc get {path} {
  variable state
  Ju get state($path)
}

proc getInfo {path {field ""}} {
  variable shadow
  if {[info exists shadow($path)]} {
    set d $shadow($path)
    if {$field ne ""} {
      return [dict get $d $field]
    }
    return $d
  }
}

proc put {path value {time 0}} {
  variable state
  variable shadow
  if {$time == 0} {
    set time [clock seconds]
  }
  # keep track of some change info for each individual value
  if {![info exists shadow($path)]} {
    set shadow($path) {v "" o "" t 0 p 0 m 0}
  }
  set d $shadow($path)
  set v [dict get $d v]
  if {$value ne $v} {
    dict set d m $time
    dict set d o $v
    dict set d v $value
  }
  dict set d p [dict get $d t]
  dict set d t $time
  set shadow($path) $d
  # now update the state itself, but only if the value has changed
  if {$value ne $v} {
    set state($path) $value
  }
}

proc putDict {data time {prefix ""}} {
  dict for {k v} $data {
    set nprefix ${prefix}$k
    if {[string match *: $k]} {
      putDict $v $time $nprefix
    } else {
      put $nprefix $v $time
    }
  }
}

proc remove {args} {
  variable state
  variable shadow
  foreach x $args {
    unset -nocomplain state($x) shadow($x)
  } 
}

proc subscribe {match cmd} {
  variable traces
  variable patterns
  lappend traces($match) $cmd
  set nonmatching [Ju omit $patterns $match]
  set patterns [list $match {*}$nonmatching]
}

proc unsubscribe {match cmd} {
  variable traces
  variable patterns
  set without [Ju omit $patterns $match]
  if {[llength $without] < [llength $patterns]} {
    set patterns $without
    Ju setOrUnset traces(match) [Ju omit $traces($match) $cmd]
  }
}

proc periodicSave {fname} {
  # Periodically save state to file, and reload it when starting up.
  variable state
  variable shadow
  set cmd [list [namespace which periodicSave] $fname]
  after cancel $cmd
  after 60000 $cmd
  if {[array size shadow] == 0} {
    array set shadow [Ju readFile $fname]
    foreach {k v} [array get shadow] {
      set state($k) [dict get $v v]
    }
    # puts "  $fname: [array size shadow] state variables"
  } else {
    set out {}
    foreach {k v} [array get shadow] {
      lappend out [list $k $v]
    }
    Ju writeFile $fname [join [lappend out ""] \n] -atomic
  }
}
