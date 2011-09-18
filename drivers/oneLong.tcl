Driver "Displays each incoming 4 bytes as a long, for testing purposes."

type remote

values {
  *: {
    value: { desc "some value" }
  }
}

proc decode {event raw} {
  bitSlicer $raw value 32
  $event submit value $value
}
