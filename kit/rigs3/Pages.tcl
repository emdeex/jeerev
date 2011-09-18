Jm doc "Main rig for supporting HTML page generation."

proc Page {text} {
  #TODO Jm doc-like behavior
}

proc load {path} {
  Jm autoLoader $path * Pages::
}

proc request {page args} {
  set vars [dict get $::main::pages ::Pages::$page]
  Request new $page [uplevel namespace current] $vars $args
}

proc pageVars {info} {
  uplevel [list variable info $info]
  #TODO this is an awkward way to do things, try to improve on it
  #  the benefit of hooks + cachedVar is automatic cleanup (but more overhead)
  uplevel { proc PAGES.VARS {} { variable info; return $info } }
}

proc pSelect {var label args} {
  Webserver expand [Sif html {
    label/for=s_$var: $label
    select/id=s_$var/data-bind=value:$var
      % foreach x $args
        option/value=[incr seq]: $x
  }]
}
proc pRadio {var label args} {
  Webserver expand [Sif html {
    : $label
    % foreach x $args
      % set tag r_${var}_[incr seq]
      input/type=radio/value=$seq/id=$tag/data-bind=checked:$var
      label/for=$tag: $x
  }]
}
proc pCheckbox {args} {
  Webserver expand [Sif html {
    % foreach {var label} $args
      % if {$var ne [lindex $args 0]}
        br
      input/type=checkbox/id=c_$var/data-bind=checked:$var
      label/for=c_$var: $label
  }]
}
proc pText {var label} {
  Webserver expand [Sif html {
    label/for=t_$var: $label
    % set akd afterkeydown
    input/type=text/id=t_$var/size=4/data-bind=value:$var,valueUpdate:"$akd"
  }]
}

Ju classDef Request {
  variable info
  
  constructor {page ns vars extra} {
    Ju extendNamespacePath $ns ::Pages::$page ::Pages
    set info [dict merge [Webserver state] $vars $extra]
    dict set info page $page
    # set up all trace variables $X(...)
    foreach avar [my types] {
      my variable $avar
      array set $avar {}
      trace add variable $avar read [callBack Tracer]
    }
  }
  
  method types {} {
    # Returns the list of all method names matching a single uppercase letter.
    lsearch -inline -all [info object methods [self] -all -private] {[A-Z]}
  }
  
  method V {x} { return $x }
  method X {x} { ne $x "" }
  method H {x} { wibble enhtml $x }
  method A {x} { wibble enattr $x }
  method P {x} { wibble enpre $x }
  method Q {x} { wibble enquery $x }

  method Tracer {a e op} {
    upvar ${a}($e) v
    if {![info exists v]} {
      # expand a:b:c notation into nested dict access
      set path [string map {: " "} $e]
      # produce a result depending on the array type used
      set v [my $a [dict get? $info {*}$path]]
    }
  }
  
  method expand {html {extra ""}} {
    my variable {*}[my types]
    set info [dict merge $info $extra]
    Webserver expand $html
  }
}
