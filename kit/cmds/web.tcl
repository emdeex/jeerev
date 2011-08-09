Jm doc "Start a demo web server on local port 8080."

proc start {{port 8080} {root .}} {
  wibble handle /vars zone::vars
  wibble handle / zone::dirslash root $root
  wibble handle / zone::indexfile root $root indexfile index.html
  wibble handle / zone::contenttype typetable {
      application/javascript  js              application/json  json
      application/pdf pdf                     audio/mid       midi?|rmi
      audio/mp4       m4a                     audio/mpeg      mp3
      audio/ogg       flac|og[ag]|spx         audio/vnd.wave  wav
      audio/webm      webm                    image/bmp       bmp
      image/gif       gif                     image/jpeg      jp[eg]|jpeg
      image/png       png                     image/svg+xml   svg
      image/tiff      tiff?                   text/css        css
      text/html       html?                   text/plain      txt
      text/xml        xml                     video/mp4       mp4|m4[bprv]
      video/mpeg      m[lp]v|mp[eg]|mpeg|vob  video/ogg       og[vx]
      video/quicktime mov|qt                  video/x-ms-wmv  wmv
  }
  wibble handle / zone::staticfile root $root
  wibble handle / zone::scriptfile root $root
  wibble handle / zone::templatefile root $root
  wibble handle / zone::dirlist root $root
  wibble handle / zone::notfound

  puts "Starting demo web server at http://127.0.0.1:$port/ ..."
  wibble listen $port
  vwait forever
}
