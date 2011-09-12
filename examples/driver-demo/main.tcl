Jm doc "How to decode messages coming from a JeeLink with RF12demo."
Jm autoLoader ./drivers

# Note: this demo uses a fixed configuration which won't match your setup.
# To try it, change the device name and the RF12-XXX.YY.Z node IDs as needed.

# connected directly via USB
set device [Config connect:device usb-A700fdxv] ;# or COMn, or /dev/ttyUSBn
Driver register $device autoSketch

# these nodes are picked up from wireless packets
Driver register RF12-868.5.2 roomNode
Driver register RF12-868.5.3 radioBlip
Driver register RF12-868.5.4 roomNode
Driver register RF12-868.5.5 roomNode
Driver register RF12-868.5.6 roomNode
Driver register RF12-868.5.19 ookRelay2
Driver register RF12-868.5.23 roomNode
Driver register RF12-868.5.24 roomNode

# report one line on the console for each decoded/submitted state change
State subscribe * {apply {x { puts "$x = [State get $x]" }}}

# now we can connect to the JeeLink and start dispatching messages to drivers
set conn [Serial connect $device 57600]
objdefine $conn forward onReceive Driver dispatch $device message
