Jm doc "Manage state variables."

proc keys {{match *}} {
  lsort [dict keys [Stored map state] $match]
}

proc get {path} {
  dict get? [Stored map state $path] v
}

proc getInfo {path {field ""}} {
  set d [Stored map state $path]
  if {$field ne ""} {
    return [dict get $d $field]
  }
  return $d
}

proc put {path value {time 0}} {
  variable traces
  if {$time == 0} {
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
  foreach x $args {
    Stored map state $x ""
  }
}

proc subscribe {match cmd} {
  variable traces
  dict lappend traces $match $cmd
}

proc unsubscribe {match cmd} {
  variable traces
  set cmds [Ju omit [dict get? [Ju get traces] $match] $cmd]
  if {[llength $cmds] > 0} {
    dict set traces $match $cmds
  } else {
    dict unset traces $match
  }
}
