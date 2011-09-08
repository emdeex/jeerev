Jm doc "Rig wrapper around the wibble web server package."

package require wibble

proc pageResponse {type text args} {
  # Convenience function to create a suitable response for wibble.
  set type [string map {
    text  text/plain
    html  text/html
    json  application/json
  } $type]
  dict set response header content-type [list "" $type charset utf-8]
  # set any additional fields passed in as args
  dict for {k v} $args {
    dict set response {*}$k $v
  }
  #FIXME whoops, reply socket isn't in UTF8 mode!
  dict set response content [encoding convertto identity $text]
}
