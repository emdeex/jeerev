Jm doc "Display all state variables as a tree in the browser."
Jm needs Webserver

variable js {
  var options = {
    core: { animation: 0 },
    plugins: [ 'themes', 'json_data' ],
    json_data: {}
  };
  $.getJSON('data.json', function(data) {
    options.json_data.data = data;
    $('#placeholder').jstree(options);
  });
}

variable html [Sif html {
  !html
    head
      meta/charset=utf-8
      title: State variable tree
      [JScript includes jstree]
      [JScript wrap $js]
      [JScript style { #aaa { width: 600px; height: 300px; } }]
    body>#placeholder
}]

proc /: {} {
  # Respond to "/" url requests.
  variable js
  variable html
  wibble pageResponse html [Webserver expand $html]
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
