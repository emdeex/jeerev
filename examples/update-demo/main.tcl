Jm doc "Demonstrate real-time web updates using Server-Sent Events."
Jm needs Webserver WebSSE

proc APP.READY {} {
  # Called once during application startup.
  Simulate
}

variable js {
  var viewModel = { counter : ko.observable("?") };
  ko.applyBindings(viewModel);

  $.eventsource({
    url: 'events/test',
    message: function (data) { viewModel.counter(data.counter); }
  });
}

variable html [Sif html {
  !html
    head
      meta/charset=utf-8
      title: Server-Sent Events demo
      [JScript includes knockout eventsource]
      [JScript wrap $js]
    body
      p: Random value:
      blockquote/data-bind=text:counter: .
      p: (should update once a second)
}]

proc /: {} {
  # Respond to "/" url requests.
  variable js
  variable html
  wibble pageResponse html [Webserver expand $html]
}

proc Simulate {} {
  # Generate new change events once a second to all web clients.
  after 1000 [namespace which Simulate]
  set value [round [* 1000000 [rand]]]
  WebSSE propagate test [Ju toJson "counter $value" -dict]
}
