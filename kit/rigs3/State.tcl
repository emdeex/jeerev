Jm doc "Manage state variables."

proc keys {{pattern *}} {
  variable state
  lsort [array names state $pattern]
}

proc get {path} {
  variable state
  Ju get state($path)
}

proc getInfo {path} {
  variable shadow
  Ju get shadow($path)
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

proc periodicSave {fname} {
  variable state
  variable shadow
  set cmd [list [namespace which periodicSave] $fname]
  after cancel $cmd
  after 60000 $cmd
  if {![info exists shadow]} {
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
