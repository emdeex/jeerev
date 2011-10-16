Jm doc "Serial port handler."
Jm needs View ;# force loading so the "Jv" command gets defined

proc VIEW {} {
  View def name,path [SysDep listSerialPorts]
}

proc connect {name baud} {
  # Create a new serial connection object.
  set path [Jv Interfaces get $name path]
  if {$path eq ""} {
    set path $name
  }
  Connection new $path $baud
}

Ju classDef Connection {
  variable timer pending fd
  
  constructor {device baudrate {timeout 0}} {
    global tcl_platform
    set timer $timeout ;# 0 : read lines, > 0 : read binary data until ms idle
    set pending ""

    set mode RDWR
    if {$tcl_platform(os) eq "Darwin"} {
      lappend mode NONBLOCK ;# avoid hanging on open
    }
    set fd [open $device $mode]
    
    if {$timer > 0} {
      chan configure $fd -translation binary
    }
    chan configure $fd -blocking 0 -buffering none -mode $baudrate,n,8,1
    chan event $fd readable [callBack OnReadable]

    switch $tcl_platform(os) {
      Darwin {
        # prevent modem ctl from blocking serial ouput
        exec stty clocal <@$fd
      }
      Linux {
        # toggle the DTR line to force a reset
        chan configure $fd -ttycontrol {DTR 0}
        after 100
        chan configure $fd -ttycontrol {DTR 1}
      }
    }
  }

  destructor {
    catch { chan close $fd }
  }

  method send {line} {
    # Send data out (also appends a newline in text mode, i.e. if timeout is 0).
    if {$timer == 0} {
      chan puts $fd $line
    } else {
      chan puts -nonewline $fd $line
    }
  }
  
  method onMessage {vname script} {
    my variable context
    set context [list $vname $script [uplevel namespace current]]
    objdefine [self] method onReceive {msg} {
      my variable context
      lassign $context vname script ns
      namespace eval $ns [list set $vname $msg]
      namespace eval $ns $script
    }
  }

  method onReceive {msg} {
    # Called whenever there is data to process.
    Log serial {msg $msg}
  }

  method onException {type args} {
    # Called when eof or some error is detected.
    Log serial {event $type $args}
    puts $args ;#TODO make the error trace optional
    my destroy
  }

  method OnReadable {} {
    # Called internally to handle chan event readable.
    # read & gets never wait, due to non-blocking mode / async I/O
    try {
      if {[chan eof $fd]} {
        my onException eof
      } elseif {$timer > 0} {
        append pending [chan read $fd]
        after cancel [callBack OnTimeout]
        after $timer [callBack OnTimeout]
      } elseif {[chan gets $fd text] > 0 && ![fblocked $fd]} {
        my onReceive $text
      }
    } on error {e o} {
      my onException warn $e $o
    }
  }

  method OnTimeout {} {
    # Called internally when no data has come in for some time.
    my onReceive $pending
    set pending ""
  }
}
