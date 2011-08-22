Jm doc "Manage state variables."

variable state    ;# array: key = varname, val = info dict
variable traces   ;# dict: key = pattern, val = subscribed commands

if {![info exists traces]} {
  array set state {}
  set traces {}
  # trace add variable state write [namespace which Tracer]
}

# proc Tracer {ar el op} {
#   variable state
#   variable traces
#   dict for {pat cmds} $traces {
#     if {[string match $pat $el]} {
#       set d $state($el)
#       foreach cmd $cmds {
#         uplevel [list {*}$cmd $el $d]
#       }
#     }
#   }
# }

proc keys {{match *}} {
  variable state
  lsort [array names state $match]
}

proc get {path} {
  variable state
  dict get? [Ju get state($path)] v
}

proc getInfo {path {field ""}} {
  variable state
  if {[info exists state($path)]} {
    set d $state($path)
    if {$field ne ""} {
      return [dict get $d $field]
    }
    return $d
  }
}

proc put {path value {time 0}} {
  variable state
  variable traces
  if {$time == 0} {
    set time [clock seconds]
  }
  # keep track of some change info for each individual value
  if {![info exists state($path)]} {
    set state($path) {v "" o "" t 0 p 0 m 0}
  }
  set d $state($path)
  set v [dict get $d v]
  if {$value ne $v} {
    dict set d m $time
    dict set d o $v
    dict set d v $value
  }
  dict set d p [dict get $d t]
  dict set d t $time
  set state($path) $d
  # propagate the change to all subscribers
  dict for {pattern cmds} $traces {
    if {[string match $pattern $path]} {
      foreach cmd $cmds {
        {*}$cmd $path
      }
    }
  }
}

proc putDict {data time {prefix ""}} {
  dict for {k v} $data {
    set newprefix ${prefix}$k
    if {[string index $k end] eq ":"} {
      putDict $v $time $newprefix
    } else {
      put $newprefix $v $time
    }
  }
}

proc remove {args} {
  variable state
  foreach x $args {
    unset -nocomplain state($x)
  } 
}

proc subscribe {match cmd} {
  variable traces
  dict lappend traces $match $cmd
}

proc unsubscribe {match cmd} {
  variable traces
  set cmds [Ju omit [dict get? $traces $match] $cmd]
  if {[llength $cmds] > 0} {
    dict set traces $match $cmds
  } else {
    dict unset traces $match
  }
}

proc periodicSave {fname} {
  # Periodically save state to file, and reload it when starting up.
  variable state
  set cmd [list [namespace which periodicSave] $fname]
  after cancel $cmd
  after 60000 $cmd
  if {[array size state] == 0} {
    array set state [Ju readFile $fname]
    # puts "  $fname: [array size state] state variables"
  } else {
    set out {}
    foreach {k v} [array get state] {
      lappend out [list $k $v]
    }
    Ju writeFile $fname [join [lappend out ""] \n] -atomic
  }
}
