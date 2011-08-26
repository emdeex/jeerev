Jm doc "Decoder for the radioBlip sketch."

# Driver values {
#   *: {
#     ping: { unit counts low 0 high 999999999 }
#     age:  { unit days   low 0 high 9999      }
#   }
# }

proc decode {event raw} {
  Driver bitSlicer $raw ping 32
  $event submit ping $ping age [/ $ping [/ 86400 64]]
}
