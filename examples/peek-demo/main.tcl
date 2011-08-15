Jm doc "Peeking into a running system to see vars, procs, etc."
Jm needs Peek
Webserver hasUrlHandlers

proc /: {} {
  # Respond to "/" url requests.
  dict set response content {Try this: <a href="/peek">Peek!</a>}
}
