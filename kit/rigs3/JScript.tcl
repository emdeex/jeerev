Jm doc "Support for jQuery, jQuery UI, etc."

# public URLs for some common JavaScript and CSS files
Ju cachedVar {urls snippets} . {
  variable urls [Ju unComment {
    # at JeeLabs.org/pub/
    core.js
      JO:js/jquery.js
    ui.js
      JO:js/jquery-ui.js
    ui.css
      JO:css/jquery-ui.css
    mobile.js
      JQ:mobile/latest/jquery.mobile.js
    coffee.js
      JO:js/coffee-script.js
    eventsource.js
      JO:js/jquery.eventsource.js
    flot.js
      JO:js/jquery.flot.js
    datatables.js
      JO:js/jquery.dataTables.js
    raphael.js
      JO:js/raphael.js
    dateformat.js
      JO:js/jquery.dateFormat.js
    knockout.js
      JO:js/knockout.js
    tablesorter.js
      JO:js/jquery.tablesorter.js
    tablesorter.css
      JO:css/tablesorter.css
    # elsewhere...
    tmpl.js
      MS:jquery.templates/beta1/jquery.tmpl.min.js
    validate.js
      MS:jquery.validate/1.8.1/jquery.validate.min.js
    tools.js
      http://cdn.jquerytools.org/1.2.5/jquery.tools.min.js
    modernizr.js
      CF:modernizr/2.0.6/modernizr.min.js
    jstree.js
      http://static.jstree.com/v.1.0pre/jquery.jstree.js
    pjax.js
      GH:defunkt/jquery-pjax/heroku/jquery.pjax.js
  }]
  variable snippets [Ju unComment {
    kodtb.js {
      # http://www.joshbuckley.co.uk/2011/07/knockout-js-datatable-bindings/
      # Copyright (c) 2011, Josh Buckley (joshbuckley.co.uk).
      # License: MIT (http://www.opensource.org/licenses/mit-license.php)
      <script type='text/javascript'>jQuery(function(){
        ko.bindingHandlers.dataTable = {
          init: function(element, valueAccessor){
            var binding = ko.utils.unwrapObservable(valueAccessor());
            if(binding.options){
              $(element).dataTable(binding.options);
            }
          },
          update: function(element, valueAccessor){
            var binding = ko.utils.unwrapObservable(valueAccessor());
            if(!binding.data){
              binding = { data: valueAccessor() }
            }
            $(element).dataTable().fnClearTable();
            $(element).dataTable().fnAddData(binding.data());
          }
        };
      });</script>
    }
    jqtree.js {
      JS< http://jeelabs.org/pub/js/jquery.jqGrid.locale-en.js >JS
      JS< http://jeelabs.org/pub/js/jqtree.js'></script> >JS
    }
    jqtree.css {
      CSS< http://jeelabs.org/pub/css/jqtree-ui.css >CSS
    }
    960.css {
      CSS< http://jeelabs.org/pub/css/960.reset.css >CSS
      CSS< http://jeelabs.org/pub/css/960.text.css >CSS
      CSS< http://jeelabs.org/pub/css/960.css >CSS    
    }
  }]
}

proc includes {args} {
  # Generate the HTML needed to insert a number of CSS and JavaScript files.
  variable snippets
  set map {
    "JS< "  "<script type='text/javascript' src='"
    " >JS"  "'></script>"
    "CSS< " "<link type='text/css' href='"
    " >CSS" "' rel='stylesheet' />"
  }
  set css {}
  foreach x [concat core $args] {
    set found 0
    set u [GetUrl $x.css]
    if {$u ne ""} {
      lappend css "<link type='text/css' href='$u' rel='stylesheet' />"
      incr found
    } elseif {[dict exists $snippets $x.css]} {
      lappend css [string map $map [dict get $snippets $x.css]]
      incr found
    }
    set u [GetUrl $x.js]
    if {$u ne ""} {
      lappend js "<script type='text/javascript' src='$u'></script>"
    } elseif {[dict exists $snippets $x.js]} {
      lappend js [string map $map [dict get $snippets $x.js]]
    } elseif {!$found} {
      error "unknown include: $x.js or $x.css"
    }
  }
  join [concat $css $js] "\n    "
}

proc GetUrl {name} {
  # Expand some shorthand notations while lokking up a URL.
  variable urls
  string map {
    JO: http://jeelabs.org/pub/
    JQ: http://code.jquery.com/
    GH: https://raw.github.com/
    CF: http://cdnjs.cloudflare.com/ajax/libs/
    MS: http://ajax.aspnetcdn.com/ajax/
    CG: http://cloud.github.com/downloads/
  } [dict get? $urls $name]
}

proc coffee {code} {
  return "<script type='text/coffescript'>$code</script>"
}

proc wrap {code} {
  # Generate wrapped HTML around JavaScript code (to be loaded on DOM-ready).
  return "<script type='text/javascript'>jQuery(function(){$code});</script>"
}

proc style {css} {
  return "<style type='text/css'>$css</style>"
}
