Jm doc "Utility code for the different hardware interfaces."

proc VIEW {} {
  set data {}
  dict for {k v} [SysDep listSerialPorts] {
    lappend data $k $v serial ""
  }
  View def name,path,type,driver $data
}
