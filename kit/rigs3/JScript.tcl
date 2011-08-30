Jm doc "Support for jQuery, jQuery UI, etc"

# public URLs for some common JavaScript and CSS files
Ju cachedVar {urls snippets} . {
  variable urls {
    core.js
      JQ:jquery.min.js
    ui.js
      JQ:ui/1.8.15/jquery-ui.min.js
    ui.css
      JQ:ui/1.8.15/themes/ui-lightness/jquery-ui.css
    mobile.js
      JQ:mobile/latest/jquery.mobile.js
    tmpl.js
      MS:jquery.templates/beta1/jquery.tmpl.min.js
    validate.js
      MS:jquery.validate/1.8.1/jquery.validate.min.js
    knockout.js
      CF:knockout/1.2.1/knockout-min.js
    eventsource.js
      GH:rwldrn/jquery.eventsource/master/jquery.eventsource.js
    flot.js
      GH:flot/flot/master/jquery.flot.js
    datatables.js
      GH:DataTables/DataTables/master/media/js/jquery.dataTables.js
    raphael.js
      CF:raphael/1.5.2/raphael-min.js
    dateformat.js
      GH:phstc/jquery-dateFormat/master/jquery.dateFormat-1.0.js
    modernizr.js
      CF:modernizr/2.0.6/modernizr.min.js
  }
  variable snippets {
    kodtb.js {
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
    }
  }
}

proc includes {args} {
  # Generate the HTML needed to insert a number of CSS and JavaScript files.
  variable snippets
  set css {}
  foreach x [concat core $args] {
    set u [GetUrl $x.css]
    if {$u ne ""} {
      lappend css "<link type='text/css' href='$u' rel='stylesheet' />"
    }
    set u [GetUrl $x.js]
    if {$u ne ""} {
      lappend js "<script type='text/javascript' src='$u'></script>"
    } elseif {[dict exists $snippets $x.js]} {
      lappend js [wrap [dict get $snippets $x.js]]
    } else {
      error "unknown include: $x.js"
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
  } [dict get? $urls $name]
}

proc coffee {code} {
  # wishful thinking...
}

proc wrap {code} {
  # Generate wrapped HTML around JavaScript code (to be loaded on DOM-ready).
  return "<script type='text/javascript'>jQuery(function(){$code});</script>"
}
