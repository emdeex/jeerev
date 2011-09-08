Jm doc "Display all state variables as a tree in the browser."
Webserver hasUrlHandlers

variable html [Ju dedent {
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset='utf-8'>
      <title>State variable tree</title>
      [JScript includes jstree]
      [JScript wrap {
        var options = {
          core: { animation: 0 },
          plugins: [ 'themes', 'json_data' ],
          json_data: {}
        };
        $.getJSON('data.json', function(data) {
          options.json_data.data = data;
          $('#placeholder').jstree(options);
        });
      }]
      <style type='text/css'>
        #aaa { width: 600px; height: 300px; }
      </style>
    </head>
    <body>
      <div id='placeholder'></div>
    </body>
  </html>
}]

proc /: {} {
  # Respond to "/" url requests.
  variable html
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
