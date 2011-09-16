Jm doc "Displays each incoming 4 bytes as a long, for testing purposes."

Driver type remote

Driver values {
  *: {
    value: { desc "some value" }
  }
}

proc decode {event raw} {
  Driver bitSlicer $raw value 32
  $event submit value $value
}
