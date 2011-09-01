Jm doc "Print out some system and environment info."

# Most of the code in here also runs with Tcl 8.5 (useful for diagnostics).

proc start {args} {
  set cmds [string tolower $args]
  switch -- $cmds {
    all { set cmds {g a c d e l m p r t} }
    "" - "?" - "-h" - "--help" { set cmds {g u}}
  }
  foreach x $cmds {
    puts ""
    if {[catch { SubCommand $x }]} {
      puts stderr $::errorInfo
      exit 1
    }
  }
  puts ""
}

namespace eval SubCommand {
  namespace export -clear {[a-z]*}
  namespace ensemble create
  
  proc autopath {} {
    puts "AUTOPATH:"
    foreach x $::auto_path {
      puts "  $x"
    }
  }

  proc commands {} {
    puts "COMMANDS:"
    foreach x [lsort -dict [glob -nocomplain $::starkit::topdir/cmds/*.tcl]] {
      puts "  [file root [file tail $x]]"
    }
  }

  proc dependencies {} {
    puts "DEPENDENCIES:"
    set exe [info nameofexe]
    switch -glob $::tcl_platform(os) {
      Windows* {
        puts "  not available - try using a tool such as 'Dependency Walker'"
      }
      Darwin {
        if {[catch {
          set out [exec otool -L $exe]
          puts [string map {"\t" "  " " (compat" "\n    (compat"} $out]
        }]} {
          puts "  'otool' not available (requires Xcode)"
        }
      }
      *x {
        if {[catch {
          puts [exec ldd [info nameofexe]]
        }]} {
          puts "  'ldd' not available"
        }
      }
    }
  }
  
  proc encodings {} {
    puts "ENCODINGS:"
    set all {}
    set line "\n "
    foreach x [lsort -dict [encoding names]] {
      if {[string length "$line $x"] > 75} {
        append all $line
        set line "\n "
      }
      append line " $x"
    }
    puts "  [string trim [append all $line]]"
  }
  
  proc general {} {
    puts "GENERAL:"

    if {![namespace exists ::startup]} {
      set vsn "NOT RUNNING"
    } elseif {[catch { set vsn $::startup::version }]} {
      set vsn "TOO OLD"
    }

    puts "       JeeMon = $vsn"
    puts "      Library = $::starkit::topdir"
    puts "     Encoding = [encoding system]"
    puts "    Directory = [pwd]"
    puts "   Executable = [info nameofexe]"
    puts "  Tcl version = [info patchlevel]"
  }
  
  proc loadable {} {
    puts "LOADABLE:"
    foreach x [lsort -dict [info loaded]] {
      lassign $x path name
      if {![catch { package require $name } vsn]} { 
        puts "  $name $vsn $path"
      }
    }
  }

  proc machdep {} {
    puts "MACHDEP:"
    upvar #0 tcl_platform "  "
    parray "  "
  }

  proc packages {} {
    puts "PACKAGES:"
    catch { package require ? }
    foreach x [lsort -dict [package names]] {
      set v [package versions $x]
      if {$v eq ""} {
        set v [package require $x]
      }
      puts "  $x $v"
    }
  }

  proc rigs {} {
    puts "RIGS:"
    foreach x [lsort -dict [dict values [array get ::auto_index] ::Jm*]] {
      puts "  [lindex $x 1]"
    }
  }

  proc tmpath {} {
    puts "TMPATH:"
    foreach x [tcl::tm::path list] {
      puts "  $x"
    }
  }

  proc usage {} {
    puts "USAGE:"
    puts "  JeeMon env ?type ...?"
    puts "\n  Where <type> is 'all' or any mix of the following options:"
    foreach x [lsort [info commands [namespace current]::*]] {
      puts "    [namespace tail $x]"
    }
    puts "  These options may be abbreviated."
  }
}
