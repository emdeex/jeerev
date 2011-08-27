Jm doc "Manage state variables."

Ju cachedVar {state traces} - {
  variable state      ;# array: key = varname, val = info dict
  variable traces {}  ;# dict: key = pattern, val = subscribed commands
  array set state [Storage map state]
}

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

proc putDict {data {time 0} {prefix ""}} {
  dict for {k v} $data {
    set newprefix ${prefix}$k
    if {[string index $k end] eq ":"} {
      putDict $v $time $newprefix
    } else {
      put $newprefix $v $time
    }
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

proc STORAGE.PERIODIC {} {
  variable state
  foreach {k v} [array get state] {
    Storage map state $k $v
  }
}
