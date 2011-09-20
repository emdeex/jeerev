Jm doc "Rig wrapper around the vlerq package."

# Note: this takes care of auto-loading vlerq when "View ..." is used.

package require vlerq

proc lookup {v key} {
  # Fetch a row by key value (probably better added to View get at some point).
  set n [lsearch [View get $v * 0] $key]
  if {$n >= 0} {
    View get $v $n
  }
}

proc keys {v} {
  # Return all the key values, sorted.
  lsort -dict [View get $v * 0]
}
