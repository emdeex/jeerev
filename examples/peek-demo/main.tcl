Jm doc "Peeking into a running system to see vars, procs, etc."
Jm needs Webserver Peek

proc /: {} {
  # Respond to "/" url requests.
  wibble pageResponse html {Try this: <a href="/peek">Peek!</a>}
}
