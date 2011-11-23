Jm doc "Manage state variables."

proc keys {{match *}} {
  # Return a sorted list of all known state variable names.
  lsort [dict keys [Stored map state] $match]
}

proc children {{prefix ""}} {
  # Return a sorted list of names of the direct children with given prefix.
  set prefix [string trim $prefix :]
  if {$prefix ne ""} { append prefix : }
  set children {}
  foreach x [dict keys [Stored map state] $prefix*] {
    set tail [string range $x [string length $prefix] end]
    lappend children [regsub {:.*} $tail {}]
  }
  lsort -unique $children
}

proc get {path} {
  # Get the value of a state variable.
  dict get? [Stored map state $path] v
}

proc getInfo {path {field ""}} {
  # Get a dict with detailed information about a state variable.
  set d [Stored map state $path]
  if {$field ne ""} {
    return [dict get $d $field]
  }
  return $d
}

proc put {path value {time ""}} {
  # Set the value of a state variable, creating it if needed.
  variable traces
  if {![string is wide -strict $time] || $time <= 0} {
    set time [clock seconds]
  }
  # keep track of some change info for each individual value
  set d [Stored map state $path]
  if {[dict size $d] == 0} {
    set d {v "" o "" t 0 p 0 m 0}
  }
  set v [dict get $d v]
  set t [dict get $d t]
  if {$value ne $v} {
    dict set d m $time
    dict set d o $v
    dict set d v $value
  } elseif {$time == $t} {
    return ;# ignore duplicate readings
  }
  dict set d p $t
  dict set d t $time
  Stored map state $path $d
  # propagate the change to all subscribers
  dict for {pattern cmds} [Ju get traces] {
    if {[string match $pattern $path]} {
      foreach cmd $cmds {
        {*}$cmd $path
      }
    }
  }
}

proc putDict {data {time 0} {prefix ""}} {
  # Store all state variable values listed in the specified dict.
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
  # Remove a state variable, if it exists.
  foreach x $args {
    Stored map state $x ""
  }
}

proc subscribe {match cmd} {
  # Set up a callback when specific state variables have changed.
  variable traces
  dict lappend traces $match $cmd
}

proc unsubscribe {match cmd} {
  # Cancel an existing callback.
  variable traces
  set cmds [Ju omit [dict get? [Ju get traces] $match] $cmd]
  if {[llength $cmds] > 0} {
    dict set traces $match $cmds
  } else {
    dict unset traces $match
  }
}

proc tree {{pattern *} {type v}} {
  # Generate a nested dict with all the state variable names unfolded.
  set nodes {}
  foreach x [lsearch -all -inline [State keys] $pattern] {
    set v [State getInfo $x]
    if {$type eq "-all"} {
      append x :
    } else {
      set v [dict get $v $type]
    }
    dict set nodes {*}[string map {: ": "} $x] $v
  }
  return $nodes
}
