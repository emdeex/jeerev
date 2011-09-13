Jm doc "Start up as a modular app, using hooks to connect features together."

variable period 60000   ;# rate at which the heartbeath hook is called (ms)

proc start {args} {
  global argv exit
  
  set needVsn v1.5
  if {![namespace exists ::startup]} {
    fail "JeeRev requires JeeMon $needVsn to run."
  }
  if {[catch { set vsn $::startup::version }]} {
    set vsn v1.3
  }
  if {$vsn < $needVsn} {
    fail "JeeRev requires JeeMon $needVsn, the current $vsn build is too old."
  }

  # no matter what the cmdline args are, make sure the "-app" key is defined
  if {[llength $argv] & 1} {
    set argv [linsert $argv 0 -app] ;# insert "-app" if the arg count is odd
  } elseif {[lindex $argv 0] eq "app"} {
    set argv -$argv ;# allow both "app" and "-app" to specify the app to run
  } else {
    dict set? argv -app . ;# look for main.tcl in curr dir if no app specified
  }
  # argv is now a dict and should not be changed any further beyond this point

  # handle special case if the "main" rig is embedded in the startup file
  if {[info exists ::startup::opts] && [dict exists $startup::opts -main]} {
    Jm prepareRig ::main
    namespace eval ::main [dict get $startup::opts -main]
    # list "main" as rig in auto_index for hooks to work
    set ::auto_index(main) [list ::Jm::loadRig [file normalize $::argv0]]
  } else {
    # try to give a helpful error message if launching is going to fail
    if {![file exists [app path]/main.tcl]} {
      set help {? help -? -h --help --usage}
      if {[llength $argv] == 2 && [lindex $argv 1] in $help} {
        puts stderr \
    "JeeMon is a portable runtime for Physical Computing and Home Automation."
        puts stderr \
    "       (see http://jeelabs.org/jeemon and https://github.com/jcw/jeemon)"
        set exe [file root [file tail [info nameofexe]]]
        app fail "Usage: $exe ?-app? <dir> ?-option <value> ...?"
      } elseif {[catch { console show }]} {
        app fail "No application startup code found."
      } else {
        puts stderr "No application startup code found."
        set ::tcl_interactive 1
        return ;# leave console open
      }
    }

    # ready to launch the main.tcl script, and optional feature rigs for it
    Jm autoLoader [app path features]
    Jm autoLoader [app path] main.tcl ;# only autoload one file
    Jm loadNow main
  }
  
  # preliminary loading has been completed, go start the hook-based event loop
  app hook APP.BOOT {*}$argv
  app hook APP.INIT
  if {![info exists exit]} {
    app hook APP.READY
    Heartbeat ;# start "ticking" on every minute
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
  update
  after 1000 ;# slight delay so the msg can always be read, even if only briefly
  if {$cleanup} {
    set ::exit $cleanup ;# will terminate the vwait in app start
  } else {
    app hook APP.FAIL 0 ;# one last hook, then bail out right away
    exit 1
  }
}

Ju cachedVar loadedRigs . {
  # Used to search for hook procs in all currently loaded rigs.
  set loadedRigs {}
  foreach {k v} [array get ::auto_index] {
    if {[string match ::Jm::loadRig* $v]} {
      lappend loadedRigs {*}[info commands ::$k]
    }
  }
}

proc hook {hook args} {
  # Apply hooks in each loaded rig that defines it.
  # hook: name of the hook proc
  # args: arguments to pass to the hook proc
  # Returns a dict: each result is added with the hook proc path as key.
  variable loadedRigs
  set results {}
  foreach path $loadedRigs {
    set cmd ${path}::$hook
    if {[llength [info commands $cmd]] > 0} {
      dict set results $path [uplevel $cmd $args]
    }
  }
  return $results
}

proc Heartbeat {} {
  # Trigger a general-purpose hook once a minute, ON the minute.
  variable period
  set ms [clock millis]
  set remain [- $period [% $ms $period]]
  after $remain [namespace which Heartbeat]
  # don't beat on startup (or if we've missed over a second!)
  if {$remain > $period - 1000} {
    app hook APP.HEARTBEAT [/ $ms 1000]
  }
}
