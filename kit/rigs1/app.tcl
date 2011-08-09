Jm doc "Start as a modular app, using hooks to connect features together."

proc start {args} {
  global exit

  if {[llength $args] == 1} {
    # generates a nice error for the most common case, doesn't catch > 1 args
    fail "Cannot start, unknown command: $args"
  }

  # include "app" so that global searches in the code will find these calls
  Jm autoLoader [app path features]
  
  if {![file exists [app path main.tcl]]} {
    fail "No application code found."
  }

  Jm autoLoader [app path] main.tcl ;# only autoload this one file
  Jm autoLoader [app path features]
  Jm loadNow main

  app hook APP.BOOT {*}$args
  app hook APP.INIT
  if {![info exists exit]} {
    app hook APP.READY
    vwait exit
  }
  app hook APP.EXIT

  exit $exit
}

proc path {{tail ""}} {
  # Returns a normalized path relative to the application directory.
  global argv
  file normalize [file join [dict get? $argv -app] $tail]
}

proc fail {msg} {
  puts stderr $msg
  after 250 ;# slight delay so the msg can always be read, even if only briefly
  exit 1
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
