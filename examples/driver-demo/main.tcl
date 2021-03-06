Jm doc "How to decode messages coming from a JeeLink with RF12demo."

Drivers load ./drivers

# Note: this demo uses a fixed configuration which won't match your setup.
# To try it, change the interface name and the RF12-XXX.YY.Z node IDs as needed.

# connected directly via USB
set interface [Config connect:interface usb-A700fdxv] ;# or COMn or /dev/ttyUSBn

# these nodes are picked up from wireless packets
Drivers register RF12-868.5.2 roomNode
Drivers register RF12-868.5.3 radioBlip
Drivers register RF12-868.5.4 roomNode
Drivers register RF12-868.5.5 roomNode
Drivers register RF12-868.5.6 roomNode
Drivers register RF12-868.5.17 oneLong
Drivers register RF12-868.5.19 ookRelay2
Drivers register RF12-868.5.23 roomNode
Drivers register RF12-868.5.24 roomNode

# report one line on the console for each decoded/submitted state change
State subscribe * {apply {x { puts "$x = [State get $x]" }}}

# now we can connect to the JeeLink and start dispatching messages to drivers
Drivers connect $interface autoSketch
