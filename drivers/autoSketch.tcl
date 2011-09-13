Jm doc "Support for auto-loading of plugins when sketches are activated."

Driver type serial -baud 57600

proc decode {event device message} {
  # Called on each incoming message.
  variable drivermap
  if {[regexp {^\[(\w+)(\.\d*)?]} $message - name] &&
      [info exists ::auto_index($name)]} {
    Log autosk {driver $device $message}
    set drivermap($device) $name
    Driver register $device $name
    #TODO need to capture serial onException to regain control as autoSketch
    # (can't test this easily on Mac OSX, as the FTDI driver panics too often!)
    Driver dispatch $device message $message
  } else {
    Log autosk {ignored $device : $message}
  }
}
