Driver "Decoder for the radioBlip sketch."

type remote

values {
  *: {
    ping: { desc "packets sent" unit counts low 0 high 999999999 }
    age:  { desc "node age"     unit days   low 0 high 9999      }
  }
}

proc decode {event raw} {
  bitSlicer $raw ping 32
  $event submit ping $ping age [/ $ping [/ 86400 64]]
}
