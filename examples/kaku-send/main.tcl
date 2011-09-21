Jm doc "Send a command to the KlikAanKlikUit remote control."
Jm needs Webserver

proc APP.READY {} {
  # Called once during application startup.

  # create a connection object
  set device [Config connect:device usb-A700fdxv]
  variable conn [Interfaces serial connect $device 57600]
}

variable js {
  $(".toggles, #group").buttonset();
  $("#gI").click();
  // use an ajax request to respond to each button
  $("button").click(function () {
    var hc = $("select").val();
    var gr = $(":checked").val();
    $.get("do/" + this.id + "/" + gr + "/" + hc);
  });
}

variable html [Sif html {
  !html
    head
      meta/charset=utf-8
      title: KAKU send
      [JScript includes ui]
      [JScript wrap $js]
    body
      % foreach x {1 2 3 4}
        p.toggles
          button#on$x: On $x
          button#off$x: Off $x
      p#group
        label: Group:
        % foreach x {I II III IV}
          input#g$x/type=radio/name=g/value=$x
          label/for=g$x: $x
      p
        label: House Code:
        select
        % foreach x {A B C D E F G H I J K L M N O P}
          option/value=$x: $x
}]

proc /: {} {
  # Respond to "/" url requests.
  variable js
  variable html
  wibble pageResponse html [Webserver expand $html]
}

proc /do/*/*/*: {device group house} {
  # Respond to KAKU on/off requests.
  variable conn
  # decode house codes A..P to 1..16
  scan $house %c h
  if {$h eq ""} { set h 1 }
  set h [expr {($h-1) % 16 + 1}]
  # combine groups I/II/III/IV and devices 1..4 into 1..64
  set g [dict get {I 0 II 1 III 2 IV 3} $group]
  set d [expr {4 * $g + [string index $device end]}]
  # construct command string to send to the RF12demo sketch
  set cmd "$h,$d,[string match on* $device]k"
  # Log the command and send it
  Log kaku {$house $group $device : $cmd}
  $conn send $cmd
}
