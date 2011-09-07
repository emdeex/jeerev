Jm doc "Demonstrate real-time web updates using Server-Sent Events."
Jm needs WebSSE
Webserver hasUrlHandlers

proc APP.READY {} {
  # Called once during application startup.
  Simulate
}

proc /: {} {
  # Respond to "/" url requests.
  set html [Ju readFile [Ju mySourceDir]/page.tmpl]
  wibble pageResponse html [wibble template $html]
}

proc Simulate {} {
  # Generate new change events once a second to all web clients.
  after 1000 [namespace which Simulate]
  set value [round [* 1000000 [rand]]]
  WebSSE propagate test [Ju toJson "counter $value" -dict]
}
