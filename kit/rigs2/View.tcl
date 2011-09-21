Jm doc "Rig wrapper around the vlerq package."

# Note: this takes care of auto-loading vlerq when "View ..." is used.

package require vlerq

Ju cachedVar views . {
  variable views {}
}

proc ::V {rig {cmd ""} args} {
  variable views
  if {[catch { dict get $views $rig } v]} {
    Jm needs $rig
    set v [::${rig}::VIEW]
    dict set views $rig $v
  }
  if {$cmd eq ""} {
    return $v
  }
  View $cmd $v {*}$args
}
