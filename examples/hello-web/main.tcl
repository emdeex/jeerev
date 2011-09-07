Jm doc "The simplest possible web server."
Webserver hasUrlHandlers

proc /: {} {
  # Respond to "/" url requests.
  wibble pageResponse html "Hello, it's <b>[clock format [clock seconds]]</b>."
}
