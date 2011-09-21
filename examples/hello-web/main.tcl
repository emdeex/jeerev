Jm doc "The simplest possible web server."
Jm needs Webserver

proc /: {} {
  # Respond to "/" url requests.
  wibble pageResponse html "Hello, it's <b>[clock format [clock seconds]]</b>."
}
