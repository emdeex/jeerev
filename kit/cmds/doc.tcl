Jm doc "Print out some documentation extracted from the source code."

proc start {{rig ""} {match *}} {
  if {$rig eq ""} {
    global auto_index
    foreach x [lsort -dict [array names auto_index {[A-Za-z]*}]] {
      lassign $auto_index($x) cmd path ns
      if {$cmd eq "::Jm::loadRig"} {
        puts "  $x"
        Jm loadNow $x
        puts "    [lindex [dict get? $::Jm::doc_strings $path] 1]"
      }
    }
  } elseif {[catch { Jm loadNow $rig }]} {
    puts "  $rig - no rig found with this name"
  } else {
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
        if {[string match "# ?*" $line]} {
          lappend comments [string range $line 2 end]
        } elseif {[string index $line 0] ne "#"} {
          break
        }
      }
      puts ""
      puts "  proc $name {$argsWithDef}"
      if {[llength $comments] > 0} {
        puts "    [join $comments "\n    "]"
      }
    }
    puts ""
  }
}
