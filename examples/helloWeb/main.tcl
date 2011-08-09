Jm doc "The simplest possible web server."

Jm needs Webserver

proc WEBSERVER.PATHS {} {
  # Return the list of commands which repond to specific URLs.
  info commands /*:
}

proc /: {} {
  # Respond to "/" url requests.
  dict set response content "Hello, it's <b>[clock format [clock seconds]]</b>."
}
