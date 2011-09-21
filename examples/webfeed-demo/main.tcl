Jm doc "How to feed readings into state variables via web requests."
Jm needs Webserver WebFeed

# report one line on the console for each decoded/submitted state change
State subscribe * {apply {x { puts "$x = [State get $x]" }}}

proc /: {} {
  # Respond to "/" url requests.
  wibble pageResponse text {Use http://127.0.0.1:8181/webfeed/<param>/<value>}
  return $response
}
