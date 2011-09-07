Jm doc "Peeking into a running system to see vars, procs, etc."
Jm needs Peek
Webserver hasUrlHandlers

proc /: {} {
  # Respond to "/" url requests.
  wibble pageResponse html {Try this: <a href="/peek">Peek!</a>}
}
