Jm doc "Allow peeking into a running application."
Jm needs wibble
namespace path ::wibble
Jm needs Webserver

proc pathAsNamespace {path} {
  # Convert the URI path into a namespace, with proper de-quoting.
  return ::[wibble dehex [string map {/ ::} [string trim $path /]]]
}

proc namespaceAsPath {ns} {
  # Convert a namespace path to a URL path
  #TODO wibble enhex?
  return [string map {% %25 / %2F :: /} $ns]
}

proc page {ns args} {
  set trail {}
  while {$ns ne ""} {
    set t [wibble enhtml [namespace tail $ns]]
    if {[llength $trail] > 0} {
      set t "<a href='/peek/info[namespaceAsPath $ns]'>$t</a>"
    }
    set trail [linsert $trail 0 $t]
    set ns [namespace qualifiers $ns]
  }
  set url Peek
  if {$trail ne "{}"} {
    set url "<a href='/peek/info/'>$url</a>"
  }
  set breadcrumbs [join [linsert $trail 0 $url] " :: "]
  wibble pageResponse html [Webserver expand {
    <html>
      <head>
        [JScript style {
          body {font-family: monospace}
          table {border-collapse: collapse; outline: 1px solid #ccc}
          th {white-space: nowrap; text-align: left; vertical-align: top}
          th, td {border: 1px solid #FFF; padding: 0 3px}
          tr:nth-child(odd) {background-color: #E8F8E8}
          tr:nth-child(even) {background-color: #F8F8F8}
          th.title {background-color: #8d958d; text-align: center}
        }]
      </head>
      <body>
        <h2>$breadcrumbs</h2>
        [join $args \n]
      </body>
    </html>
  }]
}

proc /peek: {} {
  # Theme as frame {150 100%} peek/side/ peek/main/
  list redirect peek/info/
}

proc /peek/info/**: {path} {
  set ns [pathAsNamespace $path]
  page $ns [namespaces $ns] [ensembles $ns] [classes $ns] [objects $ns] \
            [procs $ns] [commands $ns] [arrays $ns] [vars $ns]
}

proc /peek/array/**: {path} {
  set ns [pathAsNamespace $path]
  page $ns [arrayItems $ns]
}

proc /peek/class/**: {path} {
  set ns [pathAsNamespace $path]
  page $ns [ooinfo $ns class superclasses class] \
           [ooinfo $ns class subclasses class] \
           [ooinfo $ns class mixins class] \
           [ooinfo $ns object mixins class] \
           [ooinfo $ns class methods method] \
           [ooinfo $ns object methods method]
}

proc /peek/object/**: {path} {
  set ns [pathAsNamespace $path]
  page $ns [ooinfo $ns object class class] \
           [ooinfo $ns object mixins class] \
           [ooinfo $ns object methods method]
}

proc /peek/dict/**: {path} {
  set ns [pathAsNamespace $path]
  page $ns [dictItems $ns]
}

proc /peek/proc/**: {path} {
  set ns [pathAsNamespace $path]
  page $ns [procShow $ns]
}

proc /peek/method/**: {path} {
  set ns [pathAsNamespace $path]
  page $ns [methodShow $ns]
}

proc ooinfo {ns type info result} {
  if {$info in {mixins methods}} {
    set title "$type $info"
  } else {
    set title $info
  }
  Webserver expand {
    <b>[string totitle $title]</b>
    <blockquote>
    % foreach x [lsort -dict [info $type $info $ns]] {
    %   set key [namespace tail $x]
    %   set url /peek/$result[namespaceAsPath $ns]
    %   if {[string range $x 0 1] ne "::"} { append url / $key }
        <a href='$url'>$key</a>
    % }
    </blockquote>
  }
}

proc arrayItems {ns} {
  Webserver expand {
    <table>
    % foreach key [lsort -dict [array names $ns]] {
    %   set val [wibble enhtml [set ${ns}($key)]]
        <tr><th>[wibble enhtml $key]</th><td>$val</td></tr>
    % }
    </table>
  }
}

proc dictItems {ns} {
  Webserver expand {
    <table>
    % foreach v [lsort -dict [dict keys [set $ns]]] {
    %   set key [wibble enhtml [namespace tail $v]]
    %   set val [wibble enhtml [dict get [set $ns] $key]]
        <tr><th>$key</th><td>$val</td></tr>
    % }
    </table>
  }
}

proc ensembles {ns} {
  Webserver expand {
    <b>Ensembles</b>
    <blockquote>
    % foreach x [lsort -dict [info commands ${ns}::*]] {
    %   if {[namespace ensemble exists $x]} {
          [namespace tail $x]
    %   }
    % }
    </blockquote>
  }
}

proc namespaces {ns} {
  Webserver expand {
    <b>Namespaces</b>
    <blockquote>
    % foreach x [lsort -dict [namespace children ::$ns]] {
    %   set key [namespace tail $x]
    %   set url /peek/info[namespaceAsPath $x]
    %   set val "<a href='$url'>[wibble enhtml $key]</a>"
        <tr><th>$val</td></tr>
    % }
    </blockquote>
  }
}

proc classes {ns} {
  Webserver expand {
    <b>Classes</b>
    <blockquote>
    % foreach x [lsort -dict [info commands ${ns}::*]] {
    %   if {[info object isa object $x] && [info object isa class $x]} {
    %     set key [namespace tail $x]
    %     set url /peek/class[namespaceAsPath $x]
          <a href='$url'>$key</a>
    %   }
    % }
    </blockquote>
  }
}

proc objects {ns} {
  Webserver expand {
    <b>Objects</b>
    <blockquote>
    % foreach x [lsort -dict [info commands ${ns}::*]] {
    %   if {[info object isa object $x] && ![info object isa class $x]} {
    %     set key [namespace tail $x]
    %     set url /peek/object[namespaceAsPath $x]
          <a href='$url'>$key</a>
    %   }
    % }
    </blockquote>
  }
}

proc procs {ns} {
  Webserver expand {
    <b>Procs</b>
    <blockquote>
    % foreach x [lsort -dict [info procs ${ns}::*]] {
    %   set key [namespace tail $x]
    %   set url /peek/proc[namespaceAsPath $x]
        <a href='$url'>$key</a>
    % }
    </blockquote>
  }
}

proc commands {ns} {
  Webserver expand {
    <b>Commands</b>
    <blockquote>
    % foreach x [lsort -dict [info commands ${ns}::*]] {
    %   if {[llength [info procs $x]] == 0 &&
    %       ![namespace ensemble exists $x] &&
    %       ![info object isa object $x]} {
          [namespace tail $x]
    %   }
    % }
    </blockquote>
  }
}

proc arrays {ns} {
  Webserver expand {
    <b>Arrays</b>
    <blockquote>
      <table>
    %   foreach x [lsort -dict [info vars ${ns}::*]] {
    %     set key [namespace tail $x]
    %     if {[array exists $x]} {
    %       set url /peek/array[namespaceAsPath $x]
    %       set val "<a href='$url'>[array size $x] items</a>"
            <tr><th>[wibble enhtml $key]</th><td>$val</td></tr>
    %     }
    %   }
      </table>
    </blockquote>
  }
}

proc vars {ns} {
  Webserver expand {
    <b>Variables</b>
    <blockquote>
      <table>
    %   foreach x [lsort -dict [info vars ${ns}::*]] {
    %     set key [namespace tail $x]
    %     if {![array exists $x]} {
    %       if {[info exists $x]} {
    %         set val [wibble enhtml [set $x]]
              <tr><th>[wibble enhtml $key]</th><td>$val</td></tr>
    %       }
    %     }
    %   }
      </table>
    </blockquote>
  }
}

proc procShow {ns} {
  set body [info body $ns]
  # assume that the amount of white space on the last line of the body is also 
  # suitable for indenting the first line - this seems to work out nicely
  set prefix [regsub {.*\S} $body {}]
  set arglist [wibble enhtml [info args $ns]]
  Webserver expand {
    <blockquote>
      <pre>${prefix}proc [namespace tail $ns] {$arglist} {[enpre $body]}</pre>
    </blockquote>
  }
}

proc methodShow {ns} {
  set class [namespace qualifiers $ns]
  set methname [namespace tail $ns]

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

  set prefix [regsub {.*\S} $body {}]
  Webserver expand {
    <blockquote>
      <pre>${prefix}method $methname {$argnames} {[enpre $body]}</pre>
    </blockquote>
  }
}

# <% DEF aliases %>
# <b>Aliases</b>
# <blockquote>
# % foreach a [lsort [interp aliases]] {
# %   if {$path eq "[namespace qualifiers $a]::"} {
#       [namespace tail $a] - [interp alias {} $a] <br/>
# %   }
# % }
# </blockquote>
