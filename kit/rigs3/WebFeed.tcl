Jm doc "Collect readings submitted as incoming web requests."
Webserver hasUrlHandlers

proc /webfeed/*/*: {param value} {
  # Report a new reading from an incoming web request.
  set time [clock seconds]
  State put webfeed:$param $value $time
  dict set response header content-type {"" text/plain charset utf-8}
  dict set response content [clock format $time]
  return $response
}
