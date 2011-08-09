Jm doc "Global configuration settings."

# treat all unrecognized commands as get requests
namespace ensemble create -unknown {apply {{ns t args} { list ${ns}::get $t }}}

Ju cachedVar settings . {
  global argv
  # figure out the location of the config file
  set configfile [dict get? $argv -config]
  if {$configfile eq ""} {
    set configfile [app path config.txt]
  }
  # then read it in, it should be a dict after comment lines are removed
  variable settings [Ju unComment [Ju readFile $configfile]]
  # lastly, add all command line args as config "settings"
  foreach {k v} $argv {
    put [regsub {^-?} $k cmdline:] $v
  }
}

proc get {param {default ""}} {
  variable settings
  set keys [string map {: ": "} $param]
  #TODO the dict exists call should allow no args, see http://wiki.tcl.tk/17687
  if {[llength $keys] > 0 && ![dict exists $settings {*}$keys]} {
    return $default
  }
  dict get $settings {*}$keys
}

proc put {param value} {
  variable settings
  set keys [string map {: ": "} $param]
  dict set settings {*}$keys $value
}

proc dump {{param ""}} {
  puts [emit [get $param]]
}

proc emit {pairs {prefix ""}} {
  #: emit nested setting dicts in a readable format
  set out {}
  foreach x [lsort [dict keys $pairs]] {
    set y [dict get $pairs $x]
    if {[string index $x end] eq ":"} {
      set y [emit $y  "$prefix  "]
      if {$y ne ""} {
        lappend out "$prefix[list $x] {" $y "$prefix}"
        continue
      }
    }
    lappend out "$prefix[list $x $y]"
  }
  return [join $out \n]
}
