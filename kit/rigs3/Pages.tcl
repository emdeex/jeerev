Jm doc "Utility code for HTML page generation."

proc Page {text} {
  variable desc
  set desc([namespace tail [uplevel namespace current]]) $text
}

proc load {path} {
  Jm autoLoader $path * Pages::
}

proc 'select {var label args} {
  wibble template [Sif html {
    label/for=s_$var: $label
    select/id=s_$var/data-bind=value:$var
      % foreach x $args
        option/value=[incr seq]: $x
  }]
}
proc 'radio {var label args} {
  wibble template [Sif html {
    : $label
    % foreach x $args
      % set tag r_${var}_[incr seq]
      input/type=radio/value=$seq/id=$tag/data-bind=checked:$var
      label/for=$tag: $x
  }]
}
proc 'checkbox {args} {
  wibble template [Sif html {
    % foreach {var label} $args
      % if {$var ne [lindex $args 0]}
        br
      input/type=checkbox/id=c_$var/data-bind=checked:$var
      label/for=c_$var: $label
  }]
}
proc 'text {var label} {
  wibble template [Sif html {
    label/for=t_$var: $label
    % set akd afterkeydown
    input/type=text/id=t_$var/size=4/data-bind=value:$var,valueUpdate:"$akd"
  }]
}

# Shorthand notations for various forms of checking and quoting.

proc 'V {x} { Webserver state vars $x }
proc '? {x} { ne ['V $x] "" }
proc 'E {x} { wibble enhtml ['V $x] }
proc 'A {x} { wibble enattr ['V $x] }
proc 'P {x} { wibble enpre ['V $x] }
proc 'Y {x} { wibble enquery ['V $x] }
proc 'Q {x} { wibble enquote ['V $x] }
proc 'X {x} { wibble enhex ['V $x] }
proc 'T {x} { wibble entime ['V $x] }
