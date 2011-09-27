Jm doc "Utility code for HTML page generation."

proc load {path} {
  file mkdir $path
  Jm autoLoader $path * Pages::
}

variable vtableCss {
  .vtable table { margin: 1px 0 0 0; }
  .vtable th { text-align: center; background-color: #eee; }
  .vtable th, .vtable td { padding: 0 3px; }
  .vtable td > table { border: 1px solid lightgray; }
}

proc asTable {vw {nested 0}} {
  wibble template [Sif html {
    % if {!$nested}
      [JScript style $::Pages::vtableCss]
    table.vtable
      thead
        tr
          % foreach x [View names $vw]
            th>i: $x
      tbody
        % set t [View types $vw]
        % foreach x [View get $vw *] 
          tr
            % foreach y $x z $t
              % if {$z eq "V"} { set y [asTable $y 1] }
              % if {$z in {I L F D}} { set align right } else { set align left }
              td/style=text-align:$align: $y
  }]
}

proc asJson {vw} {
  set rows {}
  set types [View types $vw]
  foreach row [View get $vw *] {
    set data {}
    foreach x $row t $types {
      switch $t {
        I - L - F - D { lappend data $x }
        V             { lappend data [asJson $x] }
        default       { lappend data [Ju toJson $x -str] }
      }
    }
    lappend rows [Ju toJson $data -list -flat]
  }
  Ju toJson $rows -list -flat
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
