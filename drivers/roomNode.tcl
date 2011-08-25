Jm doc "Decoder for the roomNode sketch"

# Driver values {
#   *: {
#     light:  { desc "light"                       low 0    high 100 }
#     moved:  { desc "motion"                      low 0    high 1   }
#     humi:   { desc "humidity"    unit %          low 0    high 100 }
#     temp:   { desc "temperature" unit °C scale 1 low -250 high 500 }
#     lowbat: { desc "low battery"                 low 0    high 1   }
#   }
# }

proc decode {event raw message} {
  if {[string length $raw] == 4} {
    # struct {
    #     byte light;     // light sensor: 0..255
    #     byte moved :1;  // motion detector: 0..1
    #     byte humi  :7;  // humidity: 0..100
    #     int temp   :10; // temperature: -500..+500 (tenths)
    #     byte lobat :1;  // supply voltage dropped under 3.1V: 0..1
    # } payload;
    Driver bitSlicer $raw l 8 m 1 h 7 t -10 b 1
  } elseif {[string match "ROOM *" $message] && [llength $message] == 6} {
    lassign $message cmd l m h t b
  } else {
    error "bad data"
  }
  set l [round [/ $l 2.55]]
  $event submit light $l moved $m humi $h temp $t lobat $b
}
