Jm doc "Utility code for active hardware devices."

proc VIEW {} {
  set data {}
  dict for {k v} $::Drivers::registered {
    lappend data $k $v ""
  }
  View def name,driver,location $data
}
