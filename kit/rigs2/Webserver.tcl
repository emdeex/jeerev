Jm doc "Web server architecture."

proc APP.READY {} {
  launch [Config webserver:port 8181]
}

proc launch {port {root ""}} {
  wibble handle / [namespace which dispatch]

  wibble handle /vars zone::vars
  if {$root ne ""} {
    wibble handle / zone::dirslash root $root
    wibble handle / zone::indexfile root $root indexfile index.html
    wibble handle / zone::contenttype typetable {
        application/javascript  js              application/json  json
        application/pdf pdf                     audio/mid       midi?|rmi
        audio/mp4       m4a                     audio/mpeg      mp3
        audio/ogg       flac|og[ag]|spx         audio/vnd.wave  wav
        audio/webm      webm                    image/bmp       bmp
        image/gif       gif                     image/jpeg      jp[eg]|jpeg
        image/png       png                     image/svg+xml   svg
        image/tiff      tiff?                   text/css        css
        text/html       html?                   text/plain      txt
        text/xml        xml                     video/mp4       mp4|m4[bprv]
        video/mpeg      m[lp]v|mp[eg]|mpeg|vob  video/ogg       og[vx]
        video/quicktime mov|qt                  video/x-ms-wmv  wmv
    }
    wibble handle / zone::static root $root
    wibble handle / zone::template root $root
    wibble handle / zone::script root $root
    wibble handle / zone::dirlist root $root
  }
  wibble handle / zone::notfound

  Log web {server starting on http://127.0.0.1:$port/}
  wibble listen $port
}

proc hasUrlHandlers {} {
  # Create a hook in the caller's context so that its "/*:" procs will be found.
  set ns [uplevel namespace current]
  interp alias {} ${ns}::WEBSERVER.PATHS \
                {} namespace eval $ns { info commands /*: }
}

proc state {} {
  # Returns entire state dict, should only be called inside a request coroutine.
  upvar #2 state state
  return $state
}

proc input {} {
  # Returns a dict with the query or post variables in the current request.
  dict extract [state] request
  dict extract $request method query post
  if {$method eq "GET"} {
    set vars $query
  } elseif {$method eq "POST"} {
    set vars $post
  } else {
    return
  }
  set result {}
  dict for {k v} $vars {
    dict set result $k [lindex $v 1]
  }
  return $result
}

proc dispatch {state} {
  # Dispatch the current URI by matching it up with the configured paths.
  # state: request and option state, as provided by the web server
  if 1 {
    set reloaded [Jm reloadRigs]
    if {[llength $reloaded]} {
      Log reloaded {$reloaded}
      Ju cacheClear
    }
  }
  variable paths  ;# cachedVar, see below
  variable routes ;# cachedVar, see below
  set path [dict get $state request uri]
  regsub {\?.*} $path {} path
  Log web {path $path}
  foreach {re match} $routes {
    set args [regexp -inline $re $path]
    if {$args ne ""} {
      # construct a command with arguments taken from the path components
      set cmd [dict get $paths $match dispatch]
      if {[namespace which $cmd] eq ""} {
        set cmd [dict get $paths $match feature]::$cmd
      }
      # this is the actual command dispatch
      set result [eval [lreplace $args 0 0 $cmd]]
      # handle different cases of content delivery, redirection, etc.
      if {[dict exists $result content] || [dict exists $result contentfile]} {
        deliver $result
      }
      if {[dict exists $result redirect]} {
        redirect [dict get $result redirect]
      }
      if {[dict exists $result type]} {
        dict set result content [Theme renderHtml $result]
        deliver $result
      }
      if {[dict exists $result pass]} {
        wibble nexthandler {*}[dict get $result pass]
      }
      # repeat with the next matching route if none of the above apply
    }
  }
}

proc redirect {location} {
  dict set response status 301
  dict set response header content-type "" text/html
  dict set response header location $location
  dict set response header expires reltime -1
  dict set response header pragma "no-cache" ""
  wibble sendresponse $response
}

proc deliver {response} {
  dict set? response status 200
  dict set? response header content-type {"" text/html charset utf-8}
  wibble sendresponse $response
}

Ju cachedVar paths . {
  variable paths {}
  dict for {k v} [app hook WEBSERVER.PATHS] {
    # takes a list of /... or ::...::/... commands
    #TODO may need to also accept dicts if more info is needed
    foreach x $v {
      if {[regexp {^(:[^/]+:)?(/.*)$} $x - ns path]} {
        if {$ns ne ""} {
          set k [string trimright $ns :]
        }
        dict set paths $path dispatch $path
        dict set paths $path feature $k
      }      
    }
  }
}

Ju cachedVar routes . {
  variable paths
  variable routes {}
  # add most specific paths first
  foreach path [lsort -decreasing [dict keys $paths]] {
    # escape characters which regexp would otherwise interpret
    set re [regsub -all {[\.\[\]\^\$\(\)]} $path {\\&}]
    # change glob matches to regexp matches
    set re [regsub -all {[\*\?]} $re {[^/]&}]
    # wrap matches in capturing parentheses
    set re [regsub -all {(\[\^/\][\?\*])+} $re {(&)}]
    # two *'s in a row will match anything, including /'s
    set re [string map {{[^/]*[^/]*} {.*}} $re]
    # drop the trailing ":" from the proc name, it's not actually in the URI
    lappend routes "^[string trimright $re :]\$" $path
  }
}
