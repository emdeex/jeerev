Jm doc "Support for jQuery, jQuery UI, etc."

# public URLs for some common JavaScript and CSS files
Ju cachedVar {urls snippets} . {
  variable urls {
    core.js
      JQ:jquery.min.js
    ui.js
      JQ:ui/1.8.15/jquery-ui.min.js
    ui.css
      JQ:ui/1.8.15/themes/cupertino/jquery-ui.css
    mobile.js
      JQ:mobile/latest/jquery.mobile.js
    tmpl.js
      MS:jquery.templates/beta1/jquery.tmpl.min.js
    validate.js
      MS:jquery.validate/1.8.1/jquery.validate.min.js
    tools.js
      http://cdn.jquerytools.org/1.2.5/jquery.tools.min.js
    knockout.js
      CG:SteveSanderson/knockout/knockout-1.3.0beta.js
    eventsource.js
      GH:rwldrn/jquery.eventsource/master/jquery.eventsource.js
    flot.js
      GH:flot/flot/master/jquery.flot.js
    datatables.js
      http://www.datatables.net/download/build/jquery.dataTables.min.js
    raphael.js
      CF:raphael/1.5.2/raphael-min.js
    dateformat.js
      GH:phstc/jquery-dateFormat/master/jquery.dateFormat-1.0.js
    modernizr.js
      CF:modernizr/2.0.6/modernizr.min.js
    jstree.js
      http://static.jstree.com/v.1.0pre/jquery.jstree.js
    bootstrap.css
      http://twitter.github.com/bootstrap/assets/css/bootstrap-1.2.0.min.css
    coffee.js
      http://jashkenas.github.com/coffee-script/extras/coffee-script.js
    pjax.js
      GH:defunkt/jquery-pjax/heroku/jquery.pjax.js
  }
  variable snippets {
    kodtb.js {
      <script type='text/javascript'>jQuery(function(){
        // http://www.joshbuckley.co.uk/2011/07/knockout-js-datatable-bindings/
        // Copyright (c) 2011, Josh Buckley (joshbuckley.co.uk).
        // License: MIT (http://www.opensource.org/licenses/mit-license.php)
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
    960.css {
  <link type='text/css' href='http://960.gs/css/reset.css' rel='stylesheet' />
  <link type='text/css' href='http://960.gs/css/text.css' rel='stylesheet' />
  <link type='text/css' href='http://960.gs/css/960.css' rel='stylesheet' />      
    }
  }
}

proc includes {args} {
  # Generate the HTML needed to insert a number of CSS and JavaScript files.
  variable snippets
  set css {}
  foreach x [concat core $args] {
    set found 0
    set u [GetUrl $x.css]
    if {$u ne ""} {
      lappend css "<link type='text/css' href='$u' rel='stylesheet' />"
      incr found
    } elseif {[dict exists $snippets $x.css]} {
      lappend css [dict get $snippets $x.css]
      incr found
    }
    set u [GetUrl $x.js]
    if {$u ne ""} {
      lappend js "<script type='text/javascript' src='$u'></script>"
    } elseif {[dict exists $snippets $x.js]} {
      lappend js [dict get $snippets $x.js]
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
    JQ: http://code.jquery.com/
    GH: https://raw.github.com/
    CF: http://cdnjs.cloudflare.com/ajax/libs/
    MS: http://ajax.aspnetcdn.com/ajax/
    CG: http://cloud.github.com/downloads/
  } [dict get? $urls $name]
}

proc coffee {code} {
  #return "<script type='text/coffescript'>$code</script>"
}

proc wrap {code} {
  # Generate wrapped HTML around JavaScript code (to be loaded on DOM-ready).
  return "<script type='text/javascript'>jQuery(function(){$code});</script>"
}

proc style {css} {
  return "<style type='text/css'>$css</style>"
}
