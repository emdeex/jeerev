Jm doc "Tree manipulation utilities."

# Trees are nestable dicts with certain conventions:
#  - nested items have keys ending in ":"
#  - setting an item to the empty string removes it

proc at {vtree args} {
  # Get or set entries in a nested tree data structure.
  # The tree is stored in the "vtree" argument, which must be passed by name.
  # If the first argument ends in ":", it is used as prefix for the rest.
  # All following arg pairs are interpreted as set key / value commands.
  # Finally, a trailing single arg is treated as a get request.
  upvar $vtree tree
  set prefix {}
  if {[string index [lindex $args 0] end] eq ":"} {
    set args [lassign $args prefix]
  }
  while {[llength $args] >= 2} {
    set args [lassign $args key value]
    if {$value ne ""} {
      dict set tree {*}[string map {: ": "} $prefix$key] $value
    } else {
      dict unset tree {*}[string map {: ": "} $prefix$key]
    }
  }
  dict get? $tree {*}[string map {: ": "} $prefix[lindex $args 0]]
}
