Jm doc "Automatically loads the matching driver when a sketch starts running."

type serial -baud 57600

proc decode {event device message} {
  # Called on each incoming message.
  variable drivermap
  if {[regexp {^\[(\w+)(\.\d*)?]} $message - name] &&
      [info exists ::auto_index(Drivers::$name)]} {
    Log autosk {driver $device $message}
    set drivermap($device) $name
    register $device $name
    #TODO need to capture serial onException to regain control as autoSketch
    # (can't test this easily on Mac OSX, as the FTDI driver panics too often!)
    dispatch $device message $message
  } else {
    Log autosk {$device ignore: $message}
  }
}
