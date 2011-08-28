Jm doc "Logging, to be called as 'Log tag {msg}', where msg will be evaluated."

# Logging can be enabled and disabled per tag, tags can be any short identifier.
# Logging can also be disabled globally by defining a glob mask ("*" masks all).

variable mask   ;# can be set to a pattern to mask a group log types
variable logfd  ;# which file descriptor to send log output to (normally stdout)
variable errcnt ;# traceback error count

if {![info exists mask]} {
  set mask ""
  set logfd stdout
  set errcnt 0
}

namespace ensemble create -unknown {apply {{ns t args} { list ${ns}::DoIt $t }}}

namespace export ? ;# also allow arbitrary single characters as log type

proc mask {pattern} {
  # Set the mask with which to ignore cretain log types.
  # mask: a glob-type mask, "" masks none, "*" masks all
  variable mask $pattern
}

proc enable {args} {
  # Enable the specified log types.
  # args: list of log types to enable
  foreach x $args {
    catch { rename $x "" }
  }
}

proc disable {args} {
  # Disable the specified log types.
  # args: list of log types to disable
  foreach x $args {
    proc $x {args} {}
  }
}

proc DoIt {type msg} {
  # Default log handler.
  # type: the type of log
  # msg: the message to log
  variable mask
  if {![string match $mask $type]} {
    set msg [uplevel [list subst $msg]]
    reportLine [format {%s %8s %s} [timestamp] $type $msg]
  }
}

proc reportLine {text} {
  # Report a line of text, truncated to 80 characters with unprintables removed.
  # text: the text message to log
  variable logfd
  if {[string length $text] > 80} {
    set text [string range $text 0 78]>
  }
  regsub -all {[^ -~]} $text . text
  chan puts $logfd $text
}

proc timestamp {{millis ""} {gmt 0}} {
  # Return a nicely formatted time stamp, including milliseconds.
  # millis: time since 1970 in milliseconds
  # gmt: set to one to report in UTC time
  if {$millis eq ""} {
    set millis [clock milliseconds]
  }
  set s1 [/ $millis 1000]
  set s2 [string range $millis end-2 end]
  return "[clock format $s1 -format %T -gmt $gmt].$s2"
}

proc now {{fmt %H:%M:%S}} {
  # Return the current time of day, nicely formatted.
  # fmt: the display format to use, see "clock format"
  clock format [clock seconds] -format $fmt
}

proc traceback {{e ""} {o ""}} {
  # Show a stack traceback, and optionally also some error details.
  # e: error message, i.e. 1st arg of "on error"
  # o: error options, i.e. 2nd arg of "on error"
  variable logfd
  variable errcnt
  Log error {traceback #[incr errcnt]}
  reportLine [string repeat - 80]
  set ei [dict get? $o -errorinfo]
  if {$e ne "" || $o ne ""} {
    dict unset o -errorinfo
    reportLine "ERROR $e"
    reportLine "    > [info level -1]"
    if {$o ne ""} {
      reportLine "      $o"
    }
  }
  set if [info frame]
  set lf ""
  set pf ""
  for {set i 1} {$i < $if} {incr i} {
    set fr [info frame $i]
    set pr [dict get? $fr proc]
    set fn [dict get? $fr file]
    set ln [dict get? $fr line]
    set lv [dict get? $fr level]
    if {$pr ne "" && $fn ne ""} {
      set ft [file tail $fn]
      set nm [string trimleft $pr :]
      if {$ft ne $lf} {
        set lf $ft
        if {[string match [file root $ft]::* $nm]} {
          set ft [file ext $ft]
        }
        set at " $ft:$ln"
      } else {
        set at " :$ln"
      }
      append pf "  "
      if {$lv ne ""} {
        set cl " -> [info level [- 1 $lv]]"
      } else {
        set cl ""
      }
      reportLine $pf$nm$at$cl
    }
  }
  if {$ei ne ""} {
    reportLine [string repeat - 80]
    foreach x [split $ei \n] {
      reportLine $x
    }
    reportLine [string repeat - 80]
  }
}
