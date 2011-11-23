Jm doc "Print out some documentation extracted from the source code."

proc start {{rig ""} {match *}} {
  # List all rigs when called without args, else show docs for a specific rig.
  if {$rig eq ""} {
    global auto_index
    # locate all rigs known to the system
    foreach x [lsort -dict [array names auto_index]] {
      lassign $auto_index($x) cmd path ns
      if {$cmd eq "::Jm::loadRig"} {
        # if it really is a rig, load it to obtain the documentation
        Jm loadNow $x
        puts "  $x - [lindex [dict get? $::Jm::doc_strings $path] 1]"
      }
    }
  } elseif {[catch { Jm loadNow $rig }]} {
    puts "  $rig - no rig found with this name"
  } else {
    # Locate all the public procs in a rig, optionally matching a pattern
    foreach x [lsort [info commands "::${rig}::\[a-z]*"]] {
      set args [info args $x]
      set body [info body $x]
      set name [namespace tail $x]
      if {$match ne "" && ![string match $match $name]} continue
      # introspect to add the default argument values, if any
      set argsWithDef {}
      foreach y $args {
        if {[info default $x $y v]} {
          set y [list $y $v]
        }
        lappend argsWithDef $y
      }
      # extract the first comment lines from the procedure body, if any
      set comments {}
      foreach y [split [string trim $body] "\n"] {
        set line [string trim $y]
        # only take the first lines which look like a real comment
        if {[string match "# ?*" $line]} {
          lappend comments [string range $line 2 end]
        } elseif {[string index $line 0] ne "#"} {
          break
        }
      }
      # all data has been collected and formatted, print out the information
      puts ""
      puts "  proc $name {$argsWithDef}"
      if {[llength $comments] > 0} {
        puts "    [join $comments "\n    "]"
      }
    }
    puts ""
  }
}
