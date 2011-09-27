Jm doc "Utility code for active hardware devices."

proc VIEW {} {
  set v [View def name [dict keys [Stored map devices]]]
  View mixin $v {
    driver {v row} {
      set name [View get $v $row name]
      dict get? [Stored map devices $name] d
    }
    location {v row} {
      set name [View get $v $row name]
      dict get? [Stored map devices $name] l
    }
  }  
}

proc put {name driver location} {
  Stored map devices $name [list d $driver l $location]
  Ju cacheClear ;#FIXME much too broad to clear just the devices view!
}
