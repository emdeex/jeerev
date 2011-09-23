Jm doc "This is the default application."
Jm needs Webserver

file mkdir [app path drivers]
file mkdir [app path features]
file mkdir [app path pages]

Drivers load [app path drivers]
Pages load [app path pages]
Jm autoLoader [app path features]

proc /: {} {
  # Respond to "/" url requests.
  wibble pageResponse html "Hello, it's <b>[clock format [clock seconds]]</b>."
}
