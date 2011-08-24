Jm doc "Start up as a modular app, using hooks to connect features together."

proc start {args} {
  global argv exit

  # no matter what the cmdline args are, make sure the "-app" key is defined
  if {[llength $argv] & 1} {
    set argv [linsert $argv 0 -app] ;# insert "-app" if the arg count is odd
  } elseif {[lindex $argv 0] eq "app"} {
    set argv -$argv ;# allow both "app" and "-app" to specify the app to run
  } else {
    dict set? argv -app . ;# look for main.tcl in curr dir if no app specified
  }
  # argv is now a dict and should not be changed any further beyond this point

  # try to give a helpful error message if launching is going to fail
  if {![file exists [app path]/main.tcl]} {
    if {[llength $argv] == 2 && [lindex $argv 1] in {-? -h --help ? help}} {
      puts stderr \
  "JeeMon is a portable runtime for Physical Computing and Home Automation."
      puts stderr \
  "       (see http://jeelabs.org/jeemon and https://github.com/jcw/jeemon)"
      set exe [file root [file tail [info nameofexe]]]
      app fail "Usage: $exe ?-app? <dir> ?-option <value> ...?"
    } else {
      app fail "No application startup code found."
    }
  }

  # we're ready to launch the main.tcl script, and optional feature rigs for it
  Jm autoLoader [app path features]
  Jm autoLoader [app path] main.tcl ;# only autoload one file
  Jm loadNow main

  # preliminary loading has been completed, go start the hook-based event loop
  app hook APP.BOOT {*}$argv
  app hook APP.INIT
  if {![info exists exit]} {
    app hook APP.READY
    vwait exit
  }
  if {$exit} {
    app hook APP.FAIL $exit
  }
  app hook APP.EXIT

  # this is the sole "official" exit point for all well-behaved applications
  exit $exit
}

proc get {key {default ""}} {
  # Simple access to any option given on the command line during launch.
  global argv
  if {![dict exists $argv $key]} {
    return $default
  }
  dict get $argv $key
}

proc path {{tail ""}} {
  # Returns a normalized path relative to the application directory.
  global argv
  file normalize [file join [app get -app] $tail]
}

proc fail {msg {cleanup 0}} {
  # Catastrophic failure, print message and exit the application.
  # msg: the text to display
  # cleanup: perform a controlled shotdown if non-zero
  puts stderr $msg
  after 500 ;# slight delay so the msg can always be read, even if only briefly
  if {$cleanup} {
    set ::exit $cleanup ;# will terminate the vwait in app start
  } else {
    app hook APP.FAIL 0 ;# one last hook, then bail out right away
    exit 1
  }
}

proc hook {hook args} {
  # Apply hooks in each loaded rig that defines it.
  # hook: name of the hook proc
  # args: arguments to pass to the hook proc
  # Returns a dict: each result is added with the hook proc path as key.
  set results {}
  foreach path [PathsOfLoadedRigs] {
    set cmd ${path}::$hook
    if {[llength [info commands $cmd]] > 0} {
      dict set results $path [uplevel $cmd $args]
    }
  }
  return $results
}

proc PathsOfLoadedRigs {} {
  # Used to search for hook procs in all currently loaded rigs.
  set paths {}
  foreach {k v} [array get ::auto_index] {
    if {[string match ::Jm::loadRig* $v]} {
      lappend paths {*}[info commands ::$k]
    }
  }
  return $paths
}
