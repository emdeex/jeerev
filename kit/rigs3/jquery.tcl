Jm doc "Support for jQuery, jQuery UI, etc"

# use files from the jQuery CDN servers
variable urls
array set urls {
  core-js
    http://code.jquery.com/jquery.min.js
  ui-js
    http://code.jquery.com/ui/1.8.15/jquery-ui.min.js
  ui-css
    http://code.jquery.com/ui/1.8.15/themes/ui-lightness/jquery-ui.css
  tmpl-js
    http://ajax.aspnetcdn.com/ajax/jquery.templates/beta1/jquery.tmpl.min.js
  knockout-js
    http://cdnjs.cloudflare.com/ajax/libs/knockout/1.2.1/knockout-min.js
  eventsource-js
    http://github.com/rwldrn/jquery.eventsource/raw/master/jquery.eventsource.js
}

proc includes {args} {
  variable urls
  set css {}
  lappend js \
    "<script type='text/javascript' src='$urls(core-js)'></script>"
  foreach x $args {
    set ok 0
    if {[info exists urls($x-css)]} {
      lappend css \
        "<link type='text/css' href='$urls($x-css)' rel='stylesheet' />"
      incr ok
    }
    if {[info exists urls($x-js)]} {
      lappend js \
        "<script type='text/javascript' src='$urls($x-js)'></script>"
      incr ok
    }
    if {!$ok} { error "unknown include: $x" }
  }
  join [concat $css $js] "\n    "
}

proc script {code} {
  return "<script type='text/javascript'>jQuery(function(){$code});</script>"
}
