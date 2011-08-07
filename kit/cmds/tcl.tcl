Jm doc "Perform the Tcl script specified on the command line."

proc start {args} {
  set result [uplevel #0 [join $args " "]]
  if {$result ne ""} {
    puts $result
  }
}
