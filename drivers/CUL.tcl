Jm doc "Driver for the CUL (busware.de) USB stick."

Driver type serial -baud 9600

Driver values {
  EM*: {
    avg:   { desc "power, average"    unit W            low 0    high 4000  }
    max:   { desc "power, maximum"    unit W            low 0    high 4000  }
    total: { desc "power, cumulative" unit Wh           low 0    high 65535 }
  }
  S300*: {
    temp:  { desc "temperature"       unit °C   scale 1 low -250 high 500   }
    humi:  { desc "humidity"          unit %    scale 1 low 0    high 100   }
  }
  KS300: {
    temp:  { desc "temperature"       unit °C   scale 1 low -250 high 500   }
    humi:  { desc "humidity"          unit %            low 0    high 100   }
    wind:  { desc "wind speed"        unit km/h scale 1 low 0    high 2000  }
    rain:  { desc "rain, collected"                     low 0    high 4095  }
    rnow:  { desc "raining now"                         low 0    high 1     }
  }
}

proc connect {device} {
  # Called to connect to a device of this type.
  set conn [Serial connect $device 9600]
  $conn send "X21" ;# initialize to report the proper info
  return $conn
}

proc decode {event message} {
  # Called on each incoming message.
  if {[regexp {^([A-Z])([0-9A-F]{4,})$} $message - type msg]} {
    Decode-$type $event [binary format H* $msg]
  } else {
    Log ? {$conn: $msg}
  }
}

proc Decode-K {event raw} {
  binary scan [string reverse $raw] H* hex
  switch [string index $hex end] {
    1 {
      # S300: 118614863f -> f368416811
      if {[scan $hex %2s%3d%3d%1d - rhum temp node] == 4} {
        $event identify S300-$node
        $event submit temp $temp humi $rhum
      }
    }
    7 {
      # KS300: 71490672012a48ef -> fe84a21027609417
      if {[scan $hex %3s%3x%3d%2d%3d%1x - rain wind rhum temp flag] == 6} {
        if {$flag & 0x8} { set temp -$temp }
        set rnow [!= [& $flag 0x2] 0]
        $event identify KS300
        $event submit temp $temp humi $rhum wind $wind rain $rain rnow $rnow
      }
    }
  }
}

proc Decode-E {event raw} {
  # example 02080A3CFE09000C0029
  Driver bitSlicer $raw type 8 unit 8 seq 8 tot 16 avg 16 max 16
  $event identify EM$type-$unit
  $event submit avg [* $avg 12] max [* $max 12] total $tot
}

proc Decode-F {event raw} {
  $event identify CUL-F
  $event submit hex [binary encode hex $raw]
}

proc Decode-H {event raw} {
  $event identify CUL-H
  $event submit hex [binary encode hex $raw]
}
