Jm doc "Collect readings submitted as incoming web requests."
Jm needs Webserver

proc /webfeed/*/*: {param value} {
  # Report a new reading from an incoming web request.
  set time [clock seconds]
  State put webfeed:$param $value $time
  wibble pageResponse text [clock format $time]
}
