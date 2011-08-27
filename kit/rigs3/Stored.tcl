Jm doc "Various bits of code to handle data storage."

variable datadir ./stored  ;# the location where all datafiles are stored

proc APP.READY {} {
  map info version 1
  PeriodicSave
}

proc PeriodicSave {} {
  # trigger once a minute, ON the minute
  set remain [- 60000 [% [clock millis] 60000]]
  after $remain [namespace which PeriodicSave]
  
  app hook STORAGE.PERIODIC  
  SaveMaps
}

proc path {name} {
  variable datadir
  file join $datadir $name
}

proc MapPath {name} {
  path $name.map
}

proc map {name args} {
  # Support for simple key/value maps (currently stored as text files).

  # Maps are created on demand, and removed once they become empty.
  # Keys are also added as needed, and removed when set to the empty string.
  # Call this proc with just the map name to get the entire map as dict, call
  # it with two args to look up a key, or three args to store a keyed value.

  variable maps     ;# array: key = map name, value = map (i.e. a dict)
  variable mapInfo  ;# dict: key = map name, value = 1 if needs to be saved
  upvar 0 maps($name) map

  if {![dict exists [Ju get mapInfo] $name]} {
    set map [Ju readFile [MapPath $name]]
    dict set mapInfo $name 0
  }

  switch [llength $args] {
    0 { return [Ju get map] }
    1 { return [dict get? [Ju get map] [lindex $args 0]] }
    2 {
      lassign $args key value
      if {$value ne ""} {
        dict set map $key $value
      } else {
        dict unset map $key
      }
      dict set mapInfo $name 1
    }
    default { error "too many args: [list map $name {*}$args]" }
  }
}

proc SaveMaps {} {
  variable maps
  variable mapInfo

  dict for {name flag} $mapInfo {
    if {$flag} {
      # Ju writeFile [MapPath $name] $map -atomic
      # more readable: sort keys and put all key/value pairs on separate lines
      set out {}
      foreach x [lsort -dict [dict keys $maps($name)]] {
        lappend out [list $x [dict get $maps($name) $x]]
      }
      if {[llength $out] > 0} {
        Ju writeFile [MapPath $name] [join $out \n] -newline -atomic
        dict set mapInfo $name 0
      } else {
        file delete [MapPath $name]
        dict unset mapInfo $name
        array unset maps $name
      }
    }
  }
}
