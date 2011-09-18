Jm doc "How to dispatch and decode RF12-over-UDP packets."
Jm autoLoader ./drivers

# these nodes are picked up from wireless packets via UDP
Drivers register RF12-868.5.2 roomNode
Drivers register RF12-868.5.3 radioBlip
Drivers register RF12-868.5.4 roomNode
Drivers register RF12-868.5.5 roomNode
Drivers register RF12-868.5.6 roomNode
Drivers register RF12-868.5.19 ookRelay2
Drivers register RF12-868.5.23 roomNode
Drivers register RF12-868.5.24 roomNode

# report one line on the console for each decoded/submitted state change
State subscribe * {apply {x { puts "$x = [State get $x]" }}}

proc DispatchJeeUdp {info when prefix} {
  # Unravel incoming collectd data and turn each item into a driver dispatch.
  # Example info:
  #   addr 192.168.1.110 RF12: {868.5: {OK: {38 294864670399922176}}}
  dict extract $info addr RF12:
  dict for {freq ok} $RF12 {
    set freq [string trim $freq :]
    # track the IP address <-> RF12 config association
    State put ${prefix}$addr RF12-$freq
    Ju assert {[llength $ok] == 2}
    lassign [lindex $ok 1] hdr values
    # convert the 8-byte int values to raw data
    set bytes [binary format W* $values]
    binary scan $bytes c len
    set raw [string range $bytes 1 $len]
    # dispatch the raw data as if it came in through the RF12demo driver
    set node RF12-$freq.[% $hdr 32]
    Drivers dispatch $node raw $raw when $when
  }
}

collectd listen jeeudp -port 25827 -command [namespace which DispatchJeeUdp]
