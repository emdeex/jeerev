Jm doc "Main rig for supporting HTML page generation."

proc Page {text} {
  #TODO Jm doc-like behavior
}

proc load {path} {
  Jm autoLoader $path * Pages::
}

proc fSelect {var label args} {
  Webserver expand [Sif html {
    label/for=s_$var: $label
    select/id=s_$var/data-bind=value:$var
      % foreach x $args
        option/value=[incr seq]: $x
  }]
}
proc fRadio {var label args} {
  Webserver expand [Sif html {
    : $label
    % foreach x $args
      % set tag r_${var}_[incr seq]
      input/type=radio/value=$seq/id=$tag/data-bind=checked:$var
      label/for=$tag: $x
  }]
}
proc fCheckbox {args} {
  Webserver expand [Sif html {
    % foreach {var label} $args
      % if {$var ne [lindex $args 0]}
        br
      input/type=checkbox/id=c_$var/data-bind=checked:$var
      label/for=c_$var: $label
  }]
}
proc fText {var label} {
  Webserver expand [Sif html {
    label/for=t_$var: $label
    % set akd afterkeydown
    input/type=text/id=t_$var/size=4/data-bind=value:$var,valueUpdate:"$akd"
  }]
}
