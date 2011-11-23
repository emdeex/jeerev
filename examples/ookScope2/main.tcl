Jm doc "OOK Scope v2 - works with the ookScope.ino sketch."
package require Tk

proc APP.READY {} {
  # Called once during application startup.

  wm title . "Select device"

  ttk::treeview .all -columns {1 2} -show headings
  .all heading 1 -text "USB ID"
  .all heading 2 -text "Device"
  .all column 1 -width 130 -stretch 0
  .all column 2 -width 250
  set count 0
  foreach {id dev} [lsort -stride 2 [SysDep listSerialPorts]] {
    .all insert {} end -values [list $id $dev]
    incr count
  }
  pack .all -expand 1 -fill both
  bind .all <<TreeviewSelect>> [namespace which OokScope]
  
  if {$count == 0} {
    wm withdraw .
    tk_messageBox -type ok -message "No FTDI devices found."
    exit
  }

  # nothing to choose, save right away
  if {$count == 1} { 
    .all selection set [.all identify item 1 1]
  }
}

proc OokScope {} {
  set item [lindex [.all selection] 0]
  if {$item ne ""} {
    set devname [lindex [.all item $item -values] 0]
    wm withdraw .
    
    set conn [Interfaces serial connect $devname 57600]

    oo::objdefine $conn {
      # override connection to collect and display a histogram
      
      method setup {} {
        my variable fd w tally count info decay logarithmic smoothed \
                    minWidth maxWidth inbuf minPulses maxPulses series ofd

        set decay 0         ;# use decay to give priority to new pulses
        set logarithmic 1   ;# use logarithmic horizontal (counts) scale if set
        set smoothed 2      ;# used to detect/display peaks in the status line
        set minWidth 10     ;# pulses below this value clear the buffer
        set maxWidth 250    ;# pulses above this value process the buffer
        set minPulses 360   ;# only process if at least this many pulses
        set maxPulses 362   ;# only process if no more than this many pulses

        # used to store accepted pulse trains, commment out to disable
        set ofd [open ~/Desktop/out.tcl a]

        # take over the serial port to read raw data bytes
        chan configure $fd -translation binary

        # create the GUI window
        set w .ookScope
        toplevel $w
        canvas $w.c -width 600 -height 257
        pack $w.c
        entry $w.e -textvariable [my varname info] -border 0 -bg #eee
        pack $w.e -expand 1 -fill x
        $w.c itemconfigure t0 -fill red

        bind $w <Escape> [callBack Reset]

        my Reset

        # start updating the display once a second
        my Refresh
      }

      method OnReadable {} {
        # called whenever data is available to process the individual raw bytes
        my variable fd w count minWidth maxWidth inbuf minPulses maxPulses series
        foreach x [split [read $fd] ""] {
          incr count
          set x [scan $x %c]
          # if pulse too short, discard pending input
          if {$x < $minWidth} {
            set inbuf {}
          } else {
            lappend inbuf $x
            # if pulse is very long, process pending input
            if {$x > $maxWidth} {
              # if enough pending values, process them
              set n [llength $inbuf]
              if {$minPulses <= $n && $n <= $maxPulses} {
                set series $n
                my AcceptData
              }
              set inbuf {}
            }
          }
        }
      }

      method Reset {} {
        my variable tally count inbuf seq series ofd
        set series -
        set seq 0
        set count 0
        for {set i 0} {$i < 256} {incr i} {
          set tally($i) 0
        }
        set inbuf {}
        if {[info exists ofd]} {
          chan configure $ofd -buffering line
          puts $ofd "# reset - [clock format [clock seconds]]"
        }
      }

      method AcceptData {} {
        my variable tally decay inbuf ofd
        set cmd [list P [string range [clock sec] end-3 end] [llength $inbuf]]
        foreach x $inbuf {
          lappend cmd [my Width $x]
          if {[incr tally($x)] > 250 && $decay} {
            # decay old entries by halving all the current counts
            for {set i 0} {$i < 256} {incr i} {
              set tally($i) [expr {$tally($i) / 2}]
            }
          }
        }
        if {[info exists ofd]} {
          puts $ofd $cmd
        }
      }

      method Width {p} {
        foreach x {252 248 240 224 192 128} {
          if {$p >= $x} {
            set p [expr {($p << 1) - $x}]
          }
        }
        return [expr {$p * 4}]
      }

      method Value {p} {
        my variable tally logarithmic
        set n $tally($p)
        # scale back the counts as the tally windows get wider
        foreach x {252 248 240 224 192 128} {
          if {$p >= $x} {
            set p [expr {($p << 1) - $x}]
            set n [expr {$n >> 1}]
          }
        }
        # comment out the next line for linear scale
        if {$logarithmic && $n > 0} { return [expr {log10($n)}] }
        return $n
      }

      method Refresh {} {
        my variable w tally count seq info smoothed series
        after 1000 [callBack Refresh]

        # auto-scale
        set max 1
        for {set i 0} {$i < 256} {incr i} {
          set n [my Value $i]
          if {$n > $max} {
            set max $n
          }
        }
        set scale [expr {595.0 / $max}]

        # show some info in the window title
        wm title $w [format {ookScope2 %ds - count %d - max %.5g - scale %.4g} \
                                          [incr seq] $count $max $scale]

        # simple peak detection: up+up+down+down over smoothed value
        set prev 0
        set flags ""
        set n 0
        for {set i 0} {$i < 256} {incr i} {
          set n [expr {($smoothed * $n + $tally($i)) / ($smoothed + 1)}]
          append flags [expr {$n > $prev ? "+" : "-"}]
          set prev $n
        }
        # collect peaks as value.us
        set p {}
        foreach x [regexp -indices -inline -all {\+\+--} $flags] {
          set x [lindex $x 0]
          lappend p [my Width $x]
        }
        # report as highest first
        set info [list $series $p]

        # draw a fresh bar graph
        $w.c delete all
        for {set i 0} {$i < 256} {incr i} {
          set x [expr {round([my Value $i] * $scale) + 5}]
          set y [expr {$i + 1}]
          set color [expr {$i % 100 == 0 ? "red"
                                         : $i % 10 == 0 ? "blue"
                                                        : "gray"}]
          $w.c create line 0 $y $x $y -fill $color -tags y$i
        }
      }
    }
    
    $conn setup
  }
}
