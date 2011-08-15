Jm doc "The simplest possible web server."
Webserver hasUrlHandlers

proc /: {} {
  # Respond to "/" url requests.
  dict set response content "Hello, it's <b>[clock format [clock seconds]]</b>."
}
