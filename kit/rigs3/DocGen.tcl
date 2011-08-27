Jm doc "Experiments with ruff-like run-time documentation introspection."

proc dictFromVars {args} {
  # Returns a dict with variable names and values.
  # args: the list of variable names
  set result {}
  foreach x $args {
    dict set result $x [uplevel [list set $x]]
  }
  return $result
}

proc inspectProc {procname} {
  # Introspect to return argument names, defaults, and body of a proc.
  # procname: name of the proc, can be namespace-qualified
  # Returns a dict with the different pieces of information.
  
  set argnames [info args $procname]
  set defaults {}
  foreach n $argnames {
    if {[info default $procname $n v]} {
      lappend defaults $n $v
    }
  }
  set body [info body $procname]
  set ns [namespace qualifiers $procname]
  set name [namespace tail $procname]
  return [dictFromVars name ns argnames defaults body]
}

proc inspectMethod {class methname} {
  # Introspect to return argument names, defaults, and body of a class method.
  # class: class name, can be namespace-qualified
  # methodname: name of the method in the specified class
  # Returns a dict with the different pieces of information.
  
  switch -- $methname {
    constructor { lassign [info class constructor $class] params body }
    destructor  { lassign [info class destructor $class] body params }
    default     { lassign [info class definition $class $methname] params body }
  }

  set argnames {}
  set defaults {}
  foreach p $params {
    lassign $p n v
    lappend argnames $n
    if {[llength $p] > 1} {
      lappend defaults $n $v
    }
  }  
  set ns [namespace qualifiers $class]
  set classname [namespace tail $class]
  return [dictFromVars methname classname ns argnames defaults body]
}

proc docFromBody {body} {
  # Given a proc or method body, return the leading comment lines.
  # body: body of proc or method
  # Returns the comments with whitespace indent and "#" removed from each line.
  
  set lines {}
  regsub {^\s*\n} $body {} body
  foreach x [split $body \n] {
    if {![regsub {^\s*# ?} $x {} x]} break
    # set x [string trimright $x]
    # if {$x eq ""} continue
    lappend lines $x
  }
  return [string trim [join $lines \n]]
}
