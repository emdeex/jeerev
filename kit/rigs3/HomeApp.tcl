Jm doc "This is the default application."
Jm needs Webserver

file mkdir [app path features]
Jm autoLoader [app path features]

Drivers load [app path drivers]
Pages load [app path pages]

proc /: {} {
  # Respond to "/" url requests.
  wibble pageResponse html "Hello, it's <b>[clock format [clock seconds]]</b>."
}
