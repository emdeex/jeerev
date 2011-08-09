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
  source [app path main.tcl]

  app hook APP.BOOT {*}$args
  app hook APP.INIT
  if {![info exists exit]} {
    app hook APP.READY
    vwait exit
  }
  app hook APP.EXIT

  exit $exit
}

proc path {tail} {
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
  Log hook+ {$hook $args}
  set results {}
  foreach path [PathsOfLoadedRigs] {
    set cmd ${path}::$hook
    if {[llength [info commands $cmd]] > 0} {
      try {
        dict set results $path [uplevel $cmd $args]
      } on error {e o} {
        Log traceback $e $o
      }
    }
  }
  if {[dict size $results] > 0} {
    Log hook- {$hook [dict keys $results]}
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
