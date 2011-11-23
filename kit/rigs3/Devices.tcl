Jm doc "Utility code for active hardware devices."

proc VIEW {} {
  set v [View def name [dict keys [Stored map devices]]]
  View mixin $v {
    driver {v row} {
      set key [View get $v $row 0]
      dict get? [Stored map devices $key] d
    }
    location {v row} {
      set key [View get $v $row 0]
      dict get? [Stored map devices $key] l
    }
  }  
}

proc put {name {driver ""} {location ""}} {
  if {$driver ne ""} {
    Stored map devices $name [list d $driver l $location]
  } else {
    Stored map devices $name ""
  }
  Ju cacheClear ;#FIXME much too broad to clear just the devices view!
  app hook DEVICES.CHANGE $name
}

proc DRIVERS.DISPATCH {device info} {
  set driver [Jv Devices get $device driver]
  if {$driver ne ""} {
    # decode the incoming information via a freshly brewed event object
    set obj [Event new $driver $info]
    $obj identify $device
    # copy all decoded data to state variables
    State putDict [$obj call decode] [$obj get when 0] reading:
    # done, get rid of the event object
    $obj destroy
  } else {
    Log dispatch? {$device $info}
  }
}

Ju classDef Event {
  variable data
  
  constructor {driver values} {
    # Construct a new structure with the specified contents
    set data $values
    dict set data driver $driver
  }
  
  method get {field {default ""}} {
    if {![dict exists $data $field]} {
      return $default
    }
    dict get $data $field
  }
  
  method identify {device} {
    dict set data device $device
  }
  
  method call {subcmd} {
    # locate the decoder in the appropriate driver
    set cmd [namespace which ::Drivers::[dict get $data driver]::$subcmd]
    if {$cmd eq ""} {
      error "not found: [dict get $data driver]::$subcmd"
    }
    # pre-extract values if there are extra named arguments
    set extra [lrange [info args $cmd] 1 end]
    # call the decoder
    try {
      $cmd [self] {*}[Ju map dict get? $data $extra]
    } on error {e o} {
      Log call? {$subcmd - [Ju map dict get? $data $extra]}
      puts $e
      puts $o
    }
    # return the submitted results
    dict filter $data key *:
  }
  
  method submit {args} {
    foreach {k v} $args {
      dict set data [dict get $data device]:[dict get $data driver]: $k $v
    }
  }
}
