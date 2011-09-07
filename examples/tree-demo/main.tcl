Jm doc "Display all state variables as a tree in the browser."
Webserver hasUrlHandlers

proc /: {} {
  # Respond to "/" url requests.
  set html [Ju readFile [Ju mySourceDir]/page.tmpl]
  wibble pageResponse html [wibble template $html]
}

proc /data.json: {} {
  # Returns a JSON-formatted list / tree with all state variable names.
  wibble pageResponse json [ConvertTree [State tree]]
}

proc ConvertTree {tree} {
  # Recursively convert a nested dict to JSON, as needed by jstree.
  set nodes {}
  dict for {k v} $tree {
    if {[string index $k end] eq ":"} {
      set map [list data [Ju toJson $k -str]]
      lappend map children [ConvertTree $v]
      lappend nodes [Ju toJson $map -dict -flat]
    } else {
      # lappend nodes [Ju toJson [list data $k] -dict]
      lappend nodes [Ju toJson $k -str]
    }
  }
  Ju toJson $nodes -list -flat
}
