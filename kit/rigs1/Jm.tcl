# See Jm doc below, this rig will be loaded by "main.tcl" during startup.

proc doc {args} {
  # To be called from source files as 'Jm doc ...' to document their contents.
  variable doc_strings
  while {[incr level -1] >= -5 && ![catch { set info [info frame $level] }]} {
    if {[dict exists $info file]} {
      #TODO could use cmd or uplevel to extract current class name, etc.
      dict with info { set doc_strings($file,$line) $args }
      break
    }
  }
}

Jm doc "Additional definitions for central Jm module, loaded during startup."

proc launch {} {
  # Called once normal overridable initializations start.
  #listGlobalVars ;# debug
  #showInitialNames ;# debug
  loadExtensions
  fixModulePaths
  setupStarkit
  setupConsoleWindow
  #showAddedNames ;# debug
  return [list [locateApp] start {*}$::argv]
}

proc listGlobalVars {} {
  # Go through all global variables and arrays and list their values.
  set arraynames {}
  foreach v [lsort -dict [info vars ::*]] {
    set varname [namespace tail $v]
    if {![array exists $v]} {
      putsTruncated "$varname = [set $v]"
    } else {
      lappend arraynames $varname
    }
  }
  foreach a $arraynames {
    if {[array exists ::$a]} {
      puts ""
      putsTruncated "$a ([array size ::$a] elements)"
      foreach k [lsort -dict [array names ::$a]] {
        putsTruncated "  $k = [set ::${a}($k)]"
      }
    } else {
      putsTruncated $varname?
    }
  }
  puts ""
}

proc putsTruncated {text} {
  # Print text on std out, but replace newlines, etc. and truncate result.
  puts [truncateLine $text]
}

proc truncateLine {text {limit 80}} {
  # Truncate a string to amaximum length, replacing newlines by \n, etc.
  # text: input text
  # limit: max length
  # Returns truncated text.
  set line [string map {\n \\n \t \\t} $text]
  if {[string length $line] > $limit} {
    set line [string range $line 0 $limit-4]...
  }
  return $line
}

proc showInitialNames {} {
  # Show variables, commands, and namespaces defined by the runtime.
  puts VARS:
  puts [lsort -dict $initial::vars]
  puts COMMANDS:
  puts [lsort -dict $initial::commands]
  puts NAMESPACES:
  puts [lsort -dict $initial::namespaces]
  puts ""
}

proc showAddedNames {} {
  # Show variables, commands, and namespaces defined after startup.
  #TODO return info which can be passed back to compare against next time
  foreach {type values} [list \
                          vars [lsort -dict [info vars ::*]] \
                          commands [lsort -dict [info commands ::*]] \
                          namespaces [lsort -dict [namespace children ::]]] {
    set $type {}
    foreach x $values {
      if {$x ni [set initial::$type]} {
        lappend $type $x
      }
    }
  }
  
  puts NEW-VARS:
  puts [lsort -dict $vars]
  puts NEW-COMMANDS:
  puts [lsort -dict $commands]
  puts NEW-NAMESPACES:
  puts [lsort -dict $namespaces]
  puts ""
}

proc loadExtensions {} {
  # Extend the core Tcl commands a bit with generally-useful features.
  loadNow Jx
}

proc loadNow {rig} {
  # Loads (or re-loads) a rig, without running any subcommands.
  # rig: name of the rig to load, relative to ::
  if {![info exists ::auto_index($rig)]} {
    return -code error "no such rig: $rig"
  }
  uplevel #0 $::auto_index($rig)
}

proc fixModulePaths {} {
  # Fix the tcl::tm::path mess, add a single one pointing into this area.
  variable root_dir
  set exe [info nameofexe]
  # remove all paths which don't point inside the JeeMon exe starpack
  foreach x [::tcl::tm::path list] {
    if {![string match $exe/* $x]} {
      ::tcl::tm::path remove $x
    }
  }
  ::tcl::tm::path add $root_dir/tm
}

proc setupStarkit {} {
  # Perform standard initialization required to run as a starkit.
  package require starkit
  ::starkit::startup
}

proc setupConsoleWindow {} {
  # get a console window up as soon as possible to show progress and errors
  switch -glob $::tcl_platform(os) {
    Windows* {
      wm withdraw .
      console eval {
        .console configure -font {Courier 9}
        wm protocol . WM_DELETE_WINDOW exit
      }
      console show
    }
    Darwin {
      # uses Tk if launched as bundle app, else we're Unix'y with stdout, etc
      if {[info exists ::Jm::initial::macosx_psn]} {
        package require Tk
        wm withdraw .
        console eval {
          .console configure -font {Monaco 9}
          wm protocol . WM_DELETE_WINDOW exit
        }
        console show
      }
    }
  }
}

proc locateApp {} {
  # Standard logic for locating and loading the main application cmd.
  global argv argv0 argv1
  variable root_dir
  # if 1st arg is a dir and 2nd is a script inside, run it directly as rig
  #if {[file exists [lindex $argv 0]/[lindex $argv 1].tcl]} {
  #  set argv [lassign $argv argv0 argv1]
  #  return [Jm loadRig $argv0/$argv1.tcl]
  #}
  # if 1st arg names one of the built-in commands, load it and start as rig
  if {[file exists $root_dir/cmds/[lindex $argv 0].tcl]} {
    set argv [lassign $argv argv0]
    return [Jm loadRig $starkit::topdir/cmds/$argv0.tcl]
  }
  # else use auto-loading to find and load the actual application
  return app
}

proc reloadRigs {} {
  # Reload all rigs of which the source files have changed.
  # Returns list of reloaded rigs.
  variable rigs_loaded
  set result {}
  foreach {k v} [array get rigs_loaded] {
    lassign $v path mtime
    if {[file exists $path] && [file mtime $path] > $mtime} {
      loadRig $path [string trimleft [namespace parent $k]:: :]
      lappend result $k
    }
  }
  return $result
}

proc needs {args} {
  # Make sure all required modules are availabled amd loaded.
  # args: list of rigs to load before continuing
  foreach x $args {
    if {[info commands $x] == ""} {
      loadNow $x
    }
  }
}
