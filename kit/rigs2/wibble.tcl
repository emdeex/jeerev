Jm doc "Rig wrapper around the wibble web server package."

package require wibble

proc pageResponse {type text} {
  set type [string map {
    text  text/plain
    html  text/html
    json  application/json
  } $type]
  dict set response header content-type [list "" $type charset utf-8]
  #FIXME whoops, reply socket isn't in UTF8 mode!
  dict set response content [encoding convertto identity $text]
}