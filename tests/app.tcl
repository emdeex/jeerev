Jm doc "Standard tests for JeeRev."

variable mydir [file normalize [file dir [info script]]]

proc start {args} {
  package require tcltest
  namespace import ::tcltest::*
  configure {*}[lrange $::argv 1 end]
  singleProcess true ;# run without forking
  testsDirectory $::app::mydir
  
  # capture the fact that there were failures via a trace, since the
  # internal tcltest::failFiles variable gets cleared by cleanupTests
  trace add variable ::tcltest::failFiles write \
                          {apply {{a e op} { incr ::errors }}}
  runAllTests
  
  if {[info exists ::errors]} { exit 1 }
}
