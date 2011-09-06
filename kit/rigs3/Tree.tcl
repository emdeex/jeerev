Jm doc "Tree manipulation utilities."

proc at {vtree args} {
  upvar $vtree tree
  set prefix {}
  if {[string index [lindex $args 0] end] eq ":"} {
    set args [lassign $args next]
    lappend prefix {*}[string map {: ": "} $next]
  }
  while {[llength $args] >= 2} {
    set args [lassign $args key value]
    if {$value ne ""} {
      dict set tree {*}$prefix {*}[string map {: ": "} $key] $value
    } else {
      dict unset tree {*}$prefix {*}[string map {: ": "} $key]
    }
  }
  if {[llength $args]} {
    dict get? $tree {*}$prefix {*}[string map {: ": "} [lindex $args 0]]
  } elseif {[llength $prefix]} {
    dict get? $tree {*}$prefix
  } else {
    set tree
  }
}
