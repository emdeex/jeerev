Jm doc "Manage historical data storage"

# This code implements a very crude storage format with 14 bytes per value:
#   16b ID (short int) + 64b value (double) + 32b timestamp (long int)
# IDs are managed as a file with a list of keys and using the position as ID.
#
# Only strictly numeric values are stored, not IP addresses and other strings.
# This could easily be improved and optimized, but for now it's good enough.

proc APP.READY {} {
  variable path [Stored path history]
  
  variable fd [open $path a+]
  chan configure $fd -translation binary -buffering none
  
  State subscribe * [namespace which StateChanged]
}

proc StateChanged {name} {
  dict extract [State getInfo $name] v t
  # that funny-looking "$v == $v" condition rules out things like "NaN"
  if {[string is double -strict $v] && $v == $v} {
    AddOne $name $v $t
  }
}

proc AddOne {param value time} {
  variable path
  variable fd
  set id [Stored map history $param]
  if {$id eq ""} {
    set id [dict size [Stored map history]]
    Stored map history $param $id
  }
  puts -nonewline $fd [binary format tdn $id $value $time]
}
