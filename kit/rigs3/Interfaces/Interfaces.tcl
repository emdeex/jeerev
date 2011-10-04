Jm doc "Utility code for the different hardware interfaces."

proc VIEW {} {
  set data {}
  foreach x [array names ::auto_index Interfaces::*] {
    lappend data [namespace tail $x] [Jv $x]
  }
  #TODO the explicit subview info is needed for ungroup to work (vlerq issue #1)
  set v [View def {type,interfaces[name,path]} $data]
  # reorder name as first field so key lookup works
  View project [View ungroup $v interfaces] {name type path}
}
