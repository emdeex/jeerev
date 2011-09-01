Jm doc "Perform the Tcl script specified on the command line."

# The code in here also runs with Tcl 8.5 (useful for diagnostics).

proc start {args} {
  set result [uplevel #0 [join $args " "]]
  if {$result ne ""} {
    puts $result
  }
}
