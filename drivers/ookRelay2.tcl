Jm doc "Decoder for the radioBlip sketch"

# Driver values {
#   EM*: {
#     avg:   { desc "power, average"    unit W            low 0    high 4000  }
#     max:   { desc "power, maximum"    unit W            low 0    high 4000  }
#     total: { desc "power, cumulative" unit Wh           low 0    high 65535 }
#   }
#   S300*: {
#     temp:  { desc "temperature"       unit °C   scale 1 low -250 high 500   }
#     humi:  { desc "humidity"          unit %    scale 1 low 0    high 100   }
#   }
#   KS300: {
#     temp:  { desc "temperature"       unit °C   scale 1 low -250 high 500   }
#     humi:  { desc "humidity"          unit %            low 0    high 100   }
#     wind:  { desc "wind speed"        unit km/h scale 1 low 0    high 2000  }
#     rain:  { desc "rain, collected"                     low 0    high 4095  }
#     rnow:  { desc "raining now"                         low 0    high 1     }
#   }
# }

proc decode {event raw} {
  array set typeMap {
    1 VISO 2 EMX 3 KSX 4 FSX 5 ORSC 6 CRES 7 KAKU 8 XRF 9 HEZ
  }
  while {$raw ne ""} {
    Driver bitSlicer $raw type 4 size 4
    set name [Ju get typeMap($type) OTHER]
    Decode-$name $event [string range $raw 1 $size]
    set raw [string range $raw $size+1 end]
  }
}

proc Decode-EMX {event raw} {
  # see http://fhz4linux.info/tiki-index.php?page=EM+Protocol
  # example: EMX 0211726daefb214089007900
  Driver bitSlicer [Driver bitRemover $raw 8 1] \
          type 8 unit 8 seq 8 tot 16 avg 16 max 16
  $event identify EM$type-$unit
  $event submit avg [* $avg 12] max [* $max 12] total $tot
}

proc Decode-KSX {event raw} {
  # see http://www.dc3yc.homepage.t-online.de/protocol.htm
  # example: KSX 374309e795104a4ab54c
  # example: KSX 31ca1aabacf401
  Driver bitSlicer [Driver bitRemover $raw 4 1] \
          s 4 f 4 t0 4 t1 4 t2 4 t3 4 t4 4 t5 4 t6 4 t7 4 t8 4 t9 4 t10 4
  # the "scan" calls below are a way to get rid of extra leading zero's
  switch $s {
    1 {
      set temp [scan $t2$t1$t0 %d]
      set rhum [scan $t5$t4$t3 %d]
      if {$f & 0x8} { set temp -$temp }
      set unit [& $f 0x7]
      $event identify S300-$unit
      $event submit temp $temp humi $rhum
    }
    7 {
      # Log ksx {<$s$f-$t10$t9$t8-$t7$t6$t5-$t4$t3-$t2$t1$t0>\
      #           [binary encode hex [Driver bitRemover $raw 4 1]]}
      set temp [scan $t2$t1$t0 %d]
      set rhum [scan $t4$t3 %d]
      set wind [scan $t7$t6$t5 %d]
      set rain [+ [* 256 $t10] [* 16 $t9] $t8]
      if {$f & 0x8} { set temp -$temp }
      set rnow [expr {$f & 0x2 ? 1 : 0}]
      $event identify KS300
      $event submit temp $temp humi $rhum wind $wind rain $rain rnow $rnow
    }
    default {
      set cleaned [Driver bitRemover $raw 4 1]
      $event identify KSX-$s
      $event submit hex [binary encode hex $cleaned]
    }
  }
}

proc Decode-VISO {event raw} {
  $event identify VISO
  $event submit hex [binary encode hex $raw]
}

proc Decode-FSX {event raw} {
  $event identify FSX
  $event submit hex [binary encode hex $raw]
}

proc Decode-ORSC {event raw} {
  $event identify ORSC
  $event submit hex [binary encode hex $raw]
}

proc Decode-CRES {event raw} {
  $event identify CRES
  $event submit hex [binary encode hex $raw]
}

proc Decode-KAKU {event raw} {
  $event identify KAKU
  $event submit hex [binary encode hex $raw]
}

proc Decode-XRF {event raw} {
  $event identify XRF
  $event submit hex [binary encode hex $raw]
}

proc Decode-HEZ {event raw} {
  $event identify HEZ
  $event submit hex [binary encode hex $raw]
}

proc Decode-OTHER {event raw} {
  $event identify OTHER
  $event submit hex [binary encode hex $raw]
}
