Jm doc "Driver for the CUL (busware.de) USB stick."

# proc connect {interface} {
#   # Called for each interface of this type.
#   # interface: name of the interface
#   # Returns a dict with connection info.
#   set conn [Serial connect $interface 9600]
#   $conn send "X21" ;# initialize to report the proper info
#   dict create type serial baudrate 9600 conn $conn
# }

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
        $event submit temp $temp ;# -desc "temperature" -unit °C -scale 1
        $event submit humi $rhum ;# -desc "humidity" -unit % -scale 1
      }
    }
    7 {
      # KS300: 71490672012a48ef -> fe84a21027609417
      if {[scan $hex %3s%3x%3d%2d%3d%1x - rain wind rhum temp flag] == 6} {
        if {$flag & 0x8} { set temp -$temp }
        set rnow [!= [& $flag 0x2] 0]
        $event identify KS300
        $event submit temp $temp ;# -desc "temperature" -unit °C -scale 1
        $event submit humi $rhum ;# -desc "humidity" -unit %
        $event submit wind $wind ;# -desc "wind speed" -unit km/h -scale 1
        $event submit rain $rain ;# -desc "rain (cumulative)" -unit (0-4095)
        $event submit rnow $rnow ;# -desc "raining now" -unit (0-1)
      }
    }
  }
}

proc Decode-E {event raw} {
  # example 02080A3CFE09000C0029
  lassign [Driver bitSlicer $raw 8 8 8 16 16 16] type unit seq tot avg max
  $event identify EM$type-$unit
  $event submit avg [* $avg 12] ;# -desc "use, average" -unit W
  $event submit max [* $max 12] ;# -desc "use, maximum" -unit W
  $event submit total $tot ;# -desc "power, cumulative" -unit Wh
}

proc Decode-F {event raw} {
  $event identify CUL-F
  $event submit hex [binary encode hex $raw]
}

proc Decode-H {event raw} {
  $event identify CUL-H
  $event submit hex [binary encode hex $raw]
}
