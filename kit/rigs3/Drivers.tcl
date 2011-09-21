Jm doc "Framework for dispatching messages from devices to drivers and back."

Ju cachedVar {locations types} -once {
  variable locations {} types {}
}

proc load {path} {
  Jm autoLoader $path * Drivers::
}

proc type {type args} {
  variable types
  set driver [string trim [uplevel namespace current] :]
  dict set types $driver $type: $args
}

proc register {device driver} {
  variable registered
  Jm needs Drivers::$driver
  dict set registered $device $driver
}

proc locations {data} {
  variable locations
  set locations [dict merge $locations $data]
}

proc values {data} {
  variable values
  set driver [namespace tail [uplevel namespace current]]
  set values($driver) $data
}

proc VIEW {} {
  variable values
  set novals [View def match,var,desc,unit,scale,low:I,high:I]
  set data {}
  dict for {ns cmd} [dict filter [array get ::auto_index] key Drivers::*] {
    set name [namespace tail $ns]
    set drinfo [Ju get values($name)]
    if {[dict size $drinfo] == 0} {
      set vals $novals
    } else {
      set vdata {}
      foreach {devtype dtinfo} $drinfo {
        set dt [string trim $devtype :]
        foreach {varname vninfo} $dtinfo {
          set vn [string trim $varname :]
          # puts "<$name $dt $vn> $vninfo"
          lassign {} desc unit scale low high
          dict extract $vninfo
          lappend vdata $dt $vn $desc $unit $scale $low $high
        }
      }
      set vals [View def match,var,desc,unit,scale,low:I,high:I $vdata]
    }
    lappend data $name [View group $vals 0 vars]
  }
  View mixin [View def name,values:V $data] {
    interfaces:V {v row} {
      variable types
      set rig Drivers::[View get $v $row name]
      set interfaces {}
      foreach {k v} [dict get? $types $rig] {
        lappend interfaces [string trim $k :]
      }
      View def name $interfaces
    }
    functions:V {v row} {
      View commands ::Drivers::[View get $v $row name] {[a-z]*}
    }
    types {v row} {
      join [View get $v $row interfaces * 0] ", "
    }
    public {v row} {
      View get $v $row functions * 0
    }
  }
}

proc getInfo {driver where what} {
  variable values
  variable locations
  dict for {pattern details} [Ju get values($driver)] {
    if {[string match $pattern $where:]} {
      set info [dict get? $details $what:]
      dict set info where $where
      if {[dict exists $locations $where]} {
        dict set info location [dict get $locations $where]
      }
      return $info
    }
  }
}

proc connect {device driver} {
  variable types
  register $device $driver
  set path Drivers::$driver
  if {[namespace which ::${driver}::connect] ne ""} {
    set conn [Drivers $driver connect $device]
  } elseif {[dict exists $types $path serial:]} {
    set baud [dict get $types $path serial: -baud]
    set conn [Interfaces serial connect $device $baud]
  } else {
    return -code error "$driver: don't know how to connect to $device"
  }
  objdefine $conn forward onReceive Drivers dispatch $device message
}

proc scaledInt {value decimals} {
  if {$decimals eq ""} { return $value }
  if {$value eq ""} { set value 0 }
  set factor [** 10.0 [- $decimals]]
  if {$decimals < 0} { set decimals 0 }
  format "%.${decimals}f" [* $value $factor]
}

proc bitRemover {raw keep lose {skip 0}} {
  # Remove bits from a raw data packet in a repetitive pattern (parity, etc).
  # raw: the raw data bytes
  # keep: number of bits to keep
  # lose: number of bits to lose
  # skip: number of initial bits to ignore
  # Returns adjusted raw data.
  binary scan $raw b* bits
  set bits [string range $bits $skip end]
  set result ""
  while {$bits ne ""} {
    append result [string range $bits 0 $keep-1]
    set bits [string range $bits $keep+$lose end]
  }
  return [binary format b* $result]
}

proc bitSlicer {raw args} {
  # Take raw data bytes and slice them into integers on bit boundaries.
  # raw: the raw data bytes
  # args: pairwise list of variable names and bit counts (< 0 to sign-extend)
  binary scan $raw b* bits
  foreach {vname width} $args {
    set n [- [abs $width] 1]
    # extract bits, reverse them, then convert to an int
    set b [scan [string reverse [string range $bits 0 $n]] %b]
    if {$width < 0} {
      # sign-extend, major bit-trickery!
      set m [<< 1 $n]
      set b [- [^ $b $m] $m]
    }
    uplevel [list set $vname $b]
    set bits [string range $bits $n+1 end]
  }
}

proc bitFlipper {raw} {
  # Flip the bits in each byte.
  # raw: the raw data bytes
  binary scan $raw B* bits
  binary format b* $bits
}

proc dispatch {device args} {
  variable registered
  dict extract $args message
  if {$message ne ""} {
    app hook DRIVER.DISPATCH $device $message
  }
  set driver [dict get? $registered $device]
  if {$driver ne ""} {
    # decode the incoming information via a freshly brewed event object
    set obj [Event new $driver $args]
    $obj identify $device
    # copy all decoded data to state variables
    State putDict [$obj call decode] [$obj get when 0] reading:
    # get rid of the event object
    $obj destroy
  } else {
    Log dispatch? {$device $args}
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
