Jm doc "Manage historical data storage"

# This code implements a very crude storage format with 14 bytes per value:
#   16b ID (short int) + 64b value (double) + 32b timestamp (long int)
# IDs are managed as a file with a list of keys and using the position as ID.
#
# Only strictly numeric values are stored, not IP addresses and other strings.
# This could easily be improved and optimized, but for now it's good enough.

proc APP.READY {} {
  variable path [Config history:path ./x-hist]
  variable keys [Ju readFile $path.keys]
  
  variable fd [open $path a+]
  fconfigure $fd -translation binary -buffering none
  
  State subscribe * [namespace which StateChanged]
}

proc StateChanged {name} {
  dict extract [State getInfo $name] v t
  AddOne $name $v $t
}

proc AddOne {name value time} {
  variable path
  variable keys
  variable fd
  # that second funny-looking check rules out things like "NaN"
  if {[string is double -strict $value] && $value == $value} {
    set id [lsearch $keys $name]
    if {$id < 0} {
      set id [llength $keys]
      lappend keys $name
      Ju writeFile $path.keys [join $keys \n] -newline -atomic
    }
    puts -nonewline $fd [binary format tdn $id $value $time]
  }
}
