Jm doc "Driver for the RF12demo sketch."

proc decode {event device message} {
  # Deal with an incoming RF12 message.
  variable settings
  if {[regexp {^\[\S+\]\s\w i\S+ g(\d+) @ (\d+) MHz} $message - g m]} {
    Log RF12demo {config $device RF12-$m.$g}
    set settings($device) RF12-$m.$g
  } elseif {[string match "OK *" $message] && [info exists settings($device)]} {
    set data [lassign $message - hdr]
    set node $settings($device).[% $hdr 32]
    Driver dispatch $node raw [binary format c* $data]
  }
}
