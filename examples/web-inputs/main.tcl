Jm doc "Minimal example of how to set state variable from a web page."
Jm need Webserver

proc APP.READY {} {
  # Called once during application startup.
  State subscribe * {apply {x { puts "$x = [State get $x]" }}}
}

variable statePrefix web:demovars
variable stateVars {one two three}

# web page, in Sif format
variable html [Sif html {
  !html
    head
      meta/charset=utf-8
      title: Web input demo
    body
      h3: Web input demo
      form
        table
          % foreach x $stateVars
            tr
              td: Lamp [string toupper $x]
              td
                input/type=radio/name=$x/value=1: ON
                input/type=radio/name=$x/value=0: OFF
        input/type=submit
}]

proc /: {} {
  # Respond to "/" url requests.
  variable html
  variable statePrefix
  variable stateVars
  # decode the http query string
  set vars [Webserver input]
  if {[dict size $vars] > 0} {
    # copy all specified inputs to state variables
    dict for {k v} $vars {
      State put $statePrefix:$k $v
    }
    # force a redirect to get rid of the query in the URL
    return [Webserver redirect /]
  }
  wibble pageResponse html [Webserver expand $html]
}
