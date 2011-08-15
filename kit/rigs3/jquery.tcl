Jm doc "Support for jQuery, jQuery UI, etc"

# use files from the jQuery CDN servers
variable urls
array set urls {
  core-js http://code.jquery.com/jquery.min.js
  ui-js   http://code.jquery.com/ui/1.8.15/jquery-ui.min.js
  ui-css  http://code.jquery.com/ui/1.8.15/themes/ui-lightness/jquery-ui.css
}

proc includes {} {
  variable urls
  return "
    <link type='text/css' href='$urls(ui-css)' rel='stylesheet' />  
    <script type='text/javascript' src='$urls(core-js)'></script>
    <script type='text/javascript' src='$urls(ui-js)'></script>"
}

proc script {code} {
  return "<script type='text/javascript'>jQuery(function(){$code});</script>"
}
