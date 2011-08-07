Jm doc "Rig wrapper around the wibble web server package."

package require wibble

proc abortclient {response} {
  upvar #1 cleanup cleanup
  set cleanup [lsearch -exact -all -inline -not $cleanup {chan close $socket}]
  sendresponse $response
}
