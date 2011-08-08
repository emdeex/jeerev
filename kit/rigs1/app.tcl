Jm doc "Start as a modular app, using hooks to connect features together."

proc start {args} {
  global exit
  variable opts

	if {[llength $args] == 1} {
		fail "Cannot start, unknown command: $args"
	}

  array set opts { -mask "" -host -server -port 7489 -app app }
  array set opts $args

  Log mask $opts(-mask)

  # [Socket rpc $opts(-host) $opts(-port)] setupDispatcher

  set path $opts(-app)-features
  Jm autoLoader $path
	
	if {[catch { glob -dir $path -tails *.tcl } files]} {
	  fail "No application code found."
	}
	
  foreach f [lsort -dict $files] {
    Jm needs [file root $f]
  }

  # include "app" here so that global searches in the code will find these calls
  app hook APP.BOOT {*}$args
  app hook APP.INIT
  if {![info exists exit]} {
    app hook APP.READY
    vwait exit
  }
  app hook APP.EXIT

  exit $exit
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
