Jm doc "System-/machine-/OS-dependent code, to try and keep the rest portable."

if {[string match Windows* $::tcl_platform(os)]} {
  package require registry
  
  proc listSerialPorts {} {
    # Returns a key-value list: usb-$serial COM<N>.
    # use a spinlock to avoid race conditions if the registry changes halfway
    while 1 {
      set map [RawListSerialPorts]
      if {$map eq [RawListSerialPorts]} {
        return $map
      }
    }
  }
  
  proc RawListSerialPorts {} {
    # 2010-02-21 tested on Win2K and Win7
    # 2010-04-21 improved version, see http://talk.jeelabs.net/topic/208
    set result {}
    set ccs {HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet}
    foreach {type match} {
      Serenum {^FTDIBUS.*_6001.(\w+)}
      usbser  {^USB\B.*\B(.*)$}
    } {
      # ignore registry access errors
      catch {
        set enum "$ccs\\Services\\$type\\Enum"
        set n [registry get $enum Count]
        for {set i 0} {$i < $n} {incr i} {
          set desc [registry get $enum $i]
          if {[regexp $match $desc - serial]} {
            set p [registry get "$ccs\\Enum\\$desc\\Device Parameters" PortName]
            # Log . {usb-$serial Port: $p\
                      Friendly: [registry get "$ccs\\Enum\\$desc" FriendlyName]}
            # see http://talk.jeelabs.net/topic/569 and http://www2.tcl.tk/1838
            if {[regexp {^COM\d{2,}$} $p]} {
              set p "\\\\.\\$p"
            }
            lappend result usb-$serial $p
          }
        }
      }
    }
    return $result
  }
    
} elseif {[string match Darwin $::tcl_platform(os)]} {
  
  proc listSerialPorts {} {
    # Returns a key-value list: usb-$serial /dev/tty.usbserial-$serial.
    # 2010-02-21 tested on Mac OS X 10.6
    set result {}
    foreach path [glob -nocomplain /dev/tty.usbserial-*] {
      set name [regsub {/dev/tty.usbserial-} $path {usb-}]
      lappend result $name $path
    }
    return $result
  }

} elseif {[string match *x $::tcl_platform(os)]} {
  
  proc listSerialPorts {} {
    # Returns a key-value list: usb-$serial /dev/ttyUSB<N>.
    # 2011-01-05 tested on Ubuntu 10.10, see http://talk.jeelabs.net/topic/725
    # 2011-02-22 added extra code to pick up the FTDI serial number again
    set result {}
    foreach path [glob -nocomplain /dev/serial/by-id/*] {
      if {![regexp {usb-FTDI_.*_USB_UART_(\w+)-} $path - serial]} {
        set serial [file tail [file readlink $path]]
        regsub {^tty} $serial {} serial
      }
      set p [file normalize [file join [file dir $path] [file readlink $path]]]
      lappend result usb-$serial /dev/[file tail $p]
    }
    return $result
  }
}
