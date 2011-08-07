Jm doc "Tests for the pool and tequila functionality."

variable mydir [file normalize [file dir [info script]]]

proc start {args} {
  # need to run tests in global context (perhaps use a slave interp?)
  uplevel #0 {
      package require tcltest
      namespace import tcltest::*
      configure {*}[lrange $argv 1 end]
      singleProcess true ;# run without forking
      testsDirectory $::app::mydir
      runAllTests
  }
}
