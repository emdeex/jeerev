Jm doc "JeeMon utilities which don't fit anywhere else. Loaded only if needed."

variable quotes [list "\"" "\\\"" \\ \\\\ \b \\b \f \\f \n \\n \r \\r \t \\t]

proc get {vname {default ""}} {
  # Returns variable or array item value, or a default if not set.
  upvar $vname v
  if {[info exists v]} {
    return $v
  }
  return $default
}

proc grab {vname} {
  # Unset a variable or array element, but return the value it had before.
  upvar $vname v
  if {[info exists v]} {
    set result $v
    unset v
    return $result
  }
}

proc map {args} {
  # Maps a function to each element of a list, and returns list of the results.
  set result {}
  foreach item [lindex $args end] {
    lappend result [uplevel 1 [lreplace $args end end $item]]
  }
  return $result
}

proc tag {name args} {
  # Returns a tagged data structure, with a tag and a dict of values.
  return [dict create $name $args]
}

proc merge {vname args} {
  # Merges one or more dicts into an existing dict.
  #TODO should perform deep tarversal, for more filne-grained merging.
  upvar $vname v
  set v [dict merge $v {*}$args]
}

proc unComment {text} {
  # Remove comment lines.
  # text: input text
  return [regsub -line -all {^\s*#.*$} $text {}]
}

proc readFile {name args} {
  # Return file contents as a text string or empty if the file doesn't exist.
  # name: file name
  # args: optional -binary and -nonewline options
  if {[file exists $name]} {
    set fd [open $name]
    try {
      if {"-binary" in $args} {
        chan configure $fd -translation binary
        set args [omit $args -binary]
      } else {
        chan configure $fd -encoding utf-8
      }
      chan configure $fd -encoding utf-8
      return [chan read {*}$args $fd]
    } finally {
      chan close $fd
    }
  }
}

proc readHttp {url args} {
  # Return contents of a text file, obtained from a remote http url.
  # url: url of http page to fetch
  # args: arguments ro pass to the "http::geturl" command
  package require http
  set t [http::geturl $url {*}$args]
  try {
    if {[string match {30[1237]} [http::ncode $t]]} {
        # see http://wiki.tcl.tk/1475, special-cased for one redirection
        set m [set ${t}(meta)]
        if {[dict exists $m Location]} {
            http::cleanup $t
            set t [http::geturl [dict get $m Location] {*}$args]
        }
    }
    if {[http::status $t] ne "ok" || [http::ncode $t] != 200} {
      error "unexpected reply: [http::code $t]"
    }
    return [http::data $t]
  } finally {
    http::cleanup $t
  }
}

proc writeFile {name content args} {
  # save a string as text file, via temp file if "-atomic" is specified
  # other supported options are "-newline" and "-binary"
  if {"-atomic" in $args} { 
    append name .tmp 
  }
  file mkdir [file dir $name]
  set fd [open $name w]
  try {
    if {"-binary" in $args} {
      chan configure $fd -translation binary
    } else {
      chan configure $fd -encoding utf-8
    }
    if {"-newline" in $args} {
      chan puts $fd $content
    } else {
      chan puts -nonewline $fd $content
    }
  } finally {
    chan close $fd
  }
  if {"-atomic" in $args} {
    file rename -force $name [string range $name 0 end-4]
  }
}

proc mySourceDir {} {
  # Returns the caller's source file's directory path.
  set info [info frame -3]
  if {[dict get $info cmd] ne "Ju mySourceDir"} {
    set info [info frame -2]
    if {[dict get $info cmd] ne "Ju mySourceDir"} {
      set info [info frame -1]
    }
  }
  if {[dict exists $info file]} {
    # inside a proc
    set path [dict get $info file]
  } else {
    # assume we're at source script level
    set path [info script]
  }
  return [file normalize [file dir $path]]
}

proc launchBrowser {url} {
  # Try to launch a web browser as separate process.
  # url: which page to open
  
  # see http://wiki.tcl.tk/557
  switch -glob $::tcl_platform(os) {
    Windows* {
      exec [auto_execok start] "" $url
    }
    Darwin {
      exec open $url
    }
    default {
      foreach cmd {firefox mozilla netscape iexplorer opera lynx w3m links
                    epiphany galeon konqueror mosaic amaya browsex elinks} {
        set exe [auto_execok $cmd]
        if {$exe ne ""} {
          exec $exe $url &
          break
        }
      }     
    }
  }
}

proc extendNamespacePath {args} {
  set path [uplevel namespace path]
  uplevel [list namespace path [concat $path $args]]
}

proc scanFiles {path {notifier app} {period 3}} {
  # Periodically scan files in a directory and generate change notifications.
  # path: the directory to track
  # notifier: the notifier object to use
  # period: how to scan, in seconds
  variable lastScan
  if {![info exists lastScan]} { set lastScan {} }
  
  after ${period}000 [list [namespace which scanFiles] $path $notifier $period]

  # variable dirTime
  # set t [file mtime $path]
  # if {$t == [get dirTime 0]} return
  # set dirTime $t
  
  set prev $lastScan
  foreach f [lsort [glob -dir $path -nocomplain -tails *]] {
    set t [file mtime $path/$f]
    if {![dict exists $prev $f]} {
      dict set lastScan $f $t
      $notifier notify <newFile> %F $f %T $t %P $path
    } else {
      if {[dict get $lastScan $f] ne $t}  {
        dict set lastScan $f $t
        $notifier notify <modFile> %F $f %T $t %P $path
      }
      dict unset prev $f
    }
  }
  foreach f [dict keys $prev] {
    dict unset lastScan $f
    $notifier notify <delFile> %F $f %P $path
  }
}

proc asSeconds {duration} {
  # Convert embedded s/m/h/d/w tags or hh:mm:ss notation into seconds.
  # duration: the input spec, possibly including duration units or colons
  # Returns the result in seconds (note that a year is treated as 53 weeks).
  regsub : $duration h duration
  regsub : $duration m duration
  set abbrevs {
    s + m *60+ h *60*60+ d *60*60*24+ w *60*60*24*7+ y *60*60*24*7*53+
  }
  expr [string map $abbrevs $duration] + 0
}

proc classDef {name args} {
  # Utility to allow reloading class definitions, only created on first use.
  # name: class name
  # args: remaining arguments, passed along as is
  uplevel [list catch [list ::oo::class create $name]]
  uplevel [list ::oo::define $name {*}$args]
}

# key = ns {vname ...}
# val = tag script ?opts...?
variable cachedVars

proc cachedVar {vnames tag script args} {
  # Set up for a variable in the current namespace to be inited on demand.
  # vnames: the name of the variables in the caller's namespace
  # tag: the tag to associate with these variables, "." can be used as default
  # args: first item is script, the rest is extra, such as a cleanup script
  variable cachedVars
  set context [list [uplevel namespace current] $vnames]
  set cmd [list [namespace which CacheTracer] $context]
  set info [linsert $args 0 $tag $script]
  foreach v $vnames {
    set name v[incr seq]
    upvar $v $name
    trace remove variable $name {array read write} $cmd
    if {![info exists $name]} {
      set cachedVars($context) $info
      trace add variable $name {array read write} $cmd
    }
  }
}

proc cacheClear {{match *.*}} {
  # Clear all cache entries with a matching tag.
  # match: the pattern for tags which should be cleared
  variable cachedVars
  dict for {context info} [array get cachedVars] {
    set opts [lassign $info tag script]
    if {[string match $match $tag]} {
      lassign $context ns vnames
      set cmd [list [namespace which CacheTracer] $context]
      foreach v $vnames {
        set name ${ns}::$v
        # don't use [info exists $k] here, since that would trigger the trace
        if {[namespace which -var $name] ne ""} {
          trace remove variable $name {array read write} $cmd
          # now that the trace is gone, check whether we need to clean up
          if {[info exists $name]} {
            namespace eval $ns [dict get? $opts -cleanup]
            dict set opts -cleanup "" ;# only cleanup once
            unset $name
          }
        }
      }
      namespace inscope $ns Ju cachedVar $vnames {*}$info ;# re-arm
    }
  }
}

proc CacheTracer {context a e op} {
  # Called by cachedVar to fill in the variable, and then stop tracing.
  if {[catch {
    upvar $a v
    if {$op eq "read" && ![info exists v]} {
      variable cachedVars
      lassign $context ns
      lassign $cachedVars($context) tag script
      namespace eval $ns $script
    }
    set cmd [list [namespace which CacheTracer] $context]
    trace remove variable v {array read write} $cmd
  } m]} { Log cache {$context - $m} ;puts $::errorInfo }
}

proc pdict {_dict {_name ""}} {
  # Pretty-print a nested dict.
  array set $_name $_dict
  parray $_name
}

proc tagWithKey {key dod} {
  # Flatten a dict of dicts, sliding a top level key as tag "into" each child.
  # key: the name of the key to collect
  # dod: the "dict of dicts" input
  set r {}
  dict for {k v} $dod {
    foreach k2 [dict keys $v] {
      dict set v $k2 $key $k
    }
    lappend r $v
  }
  dict merge {*}$r
}

proc omit {list key} {
  # Return a list from which the specified key has been omitted.
  lsearch -all -inline -exact -not $list $key
}

# proc setOrUnset {avar list} {
#   upvar $avar avar
#   if {[llength $list] > 0} {
#     set avar $list
#   } else {
#     unset -nocomplain avar
#   }
# }

proc toJson {value args} {
  # Convert a value to JSON format (-dict converts dicts, -str forces string).
  set nested [expr {"-flat" ni $args}]
  if {"-dict" in $args} {
    set out {}
    dict for {k v} $value {
      if {[string index $k end] eq ":"} {
        if {$nested} { set v [toJson $v -dict] }
        lappend out "[toJson [string range $k 0 end-1] -str]:$v"
      } else {
        if {$nested} { set v [toJson $v] }
        lappend out "[toJson $k -str]:$v"
      }
    }
    return "{[join $out ,]}"
  }
  if {"-list" in $args} {
    set out {}
    foreach v $value {
      if {$nested} { set v [toJson $v] }
      lappend out $v
    }
    return "\[[join $out ,]]"
  }
  if {"-str" ni $args && [string is double -strict $value]} {
    return [expr $value]
  }
  variable quotes
  return "\"[::string map $quotes $value]\""
}

proc fromJson {text} {
  # Parse JSON to a Tcl value.
  package require json
  json::json2dict $text
}

proc toNets {value {flag ""}} {
  # Convert a value to netstring format (add -dict flag to convert dicts).
  if {$flag eq "-dict"} {
    set out {}
    dict for {k v} $value {
      append out [toNets $k]
      if {[string index $k end] eq ":"} {
        append out [toNets [toNets $v -dict]]
      } else {
        append out [toNets $v]
      }
    }
    return $out
  }
  return "[string length $value]:$value,"
}

proc fromNets {text} {
  # Parse a netstring to a Tcl value, automatically detects (nested) dicts.
  set out ""
  while {[regexp {^(\d+):(.*)} $text - len tail]} {
    set value [string range $tail 0 $len-1]
    if {[llength $out] % 2 && [string index [lindex $out end] end] eq ":"} {
      set value [fromNets $value] ;# odd entries are nested netstrings
    }
    lappend out $value
    if {[string index $tail $len] ne ","} {
      error "malformed netstring text"
    }
    set text [string range $tail $len+1 end]
  }
  if {[llength $out] == 0} {
    return [lindex $out 0]
  }
  return $out
}

proc assert {cond} {
  # Basic assertion logic - fails with an error when condition evals to false.
  if {![uplevel [list expr $cond]]} {
    return -code error "assertion failed: $cond"
  }
}
