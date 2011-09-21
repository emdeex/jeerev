Jm doc "A collection of useful extensions for Tcl."
# This code is loaded by Jm.tcl early during startup, hence always available.

# I18N is supported with [: "..."] as shorthand for [msgcat::mc "..."]
interp alias {} : {} msgcat mc

# shorthand for expr (braces are still required!)
# interp alias {} = {} expr

# let's take the plunge and make all math operators and functions global
uplevel #0 namespace import tcl::mathop::*
uplevel #0 namespace import tcl::mathfunc::*

proc ::bgerror {msg} {
  set header "$msg (ERROR #[incr ::errorCount])"
  set footer "[clock format [clock seconds]] (ERROR #$::errorCount)"
  puts stderr [string range "[string repeat - 79] $header" end-78 end]
  puts stderr $::errorInfo
  puts stderr [string range "[string repeat = 79] $footer" end-78 end]
}

# TclOO commands are considered part of the core, so let's make them global
if {[namespace exists ::oo]} {
  uplevel #0 namespace import oo::*

  namespace eval ::oo {
    Jm doc "Extensions for use inside TclOO classes."
  
    proc Helpers::callBack {meth args} {
      # see "Easier Callbacks" at http://wiki.tcl.tk/21595
      list [uplevel 1 {namespace which my}] $meth {*}$args
    }

    proc Helpers::classVar {args} {
      # see "Class Variables" at http://wiki.tcl.tk/21595
      if {[package vsatisfies [package require Tcl] 8.6b1.1]} {
        # get reference to class’s namespace
        set ns [info object namespace [uplevel 1 {self class}]]
      } else {
        #FIXME workaround is to invent a unique namespace for class vars
        set ns [uplevel 1 {self class}]_classVars
      }
      namespace eval $ns {}
      # Double up the list of varnames
      set vs {}
      foreach v $args {lappend vs $v $v}
      # Link the caller’s locals to the class’s variables
      tailcall namespace upvar $ns {*}$vs
    }

    proc define::classMethod {name {args ""} {body ""}} {
      # Create the method on the class if the caller gave arguments and body.
      # see "Class (Static) Methods" at http://wiki.tcl.tk/21595
      set argc [llength [info level 0]]
      if {$argc == 4} {
        uplevel 1 [list self method $name $args $body]
      } elseif {$argc == 3} {
        return -code error "wrong # args:\
              should be \"[lindex [info level 0] 0] name ?args body?\""
      }
      # Get the name of the current class
      set cls [lindex [info level -1] 1]
      # Get its private “my” command
      set my [info object namespace $cls]::my
      # Make the connection by forwarding
      tailcall forward $name $my $name
    }
  }
}

namespace eval dict-extensions {
  Jm doc "Some additional sub-commands for dict."
  
  proc get? {dict args} {
    # Modeled after "dict get?" courtesy patthoyts and CMcC.
    if {[llength $args] == 0 || [dict exists $dict {*}$args]} {
      dict get $dict {*}$args
    }
  }

  proc set? {var args} {
    # Set a dict element, but only if it doesn't already exist.
    upvar 1 $var dvar
    set val [lindex $args end]
    set name [lrange $args 0 end-1]

    if {![info exists dvar] || ![dict exists $dvar {*}$name]} {
      dict set dvar {*}$name $val
    }
    return $dvar
  }

  proc extract {value args} {
    # Extract specified values into variables, set to empty string if missing.
    # Note: all non-alphanumerics are stripped from the key when generating the
    # variable names. This allows extracting key "-a" to "a", "b:" to "b", etc.
    if {[llength $args] == 0} {
      set args [dict keys $value]
    }
    foreach x $args {
      uplevel [list set [regsub -all {\W} $x {}] [dict get? $value $x]]
    }
  }
  
  proc inject {vname args} {
    # Inject variable values into a dict, if they exist.
    upvar $vname v
    foreach x $args {
      if {[uplevel [list info exists $x]]} {
        dict set v $x [uplevel [list set $x]]
      }
    }
    return $v
  }
  
  proc ExtendEnsembleMap {ns args} {
    # Utility code to simplify extending an existing ensemble map.
    # ns: namespace containing the new commands
    # args: list of commands to add
    set map [namespace inscope $ns namespace ensemble configure dict -map]
    foreach x $args {
      dict set map $x [uplevel [list namespace which $x]]
    }
    namespace inscope $ns namespace ensemble configure dict -map $map
  }

  ExtendEnsembleMap ::tcl::dict get? set? extract inject
}
