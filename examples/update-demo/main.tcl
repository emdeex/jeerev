Jm doc "Demonstrate real-time web updates using Server-Sent Events."
Jm needs WebSSE
Webserver hasUrlHandlers

proc APP.READY {} {
  # Called once during application startup.
  Simulate
}

variable html [Ju dedent {
  <!DOCTYPE html>
  <html>
    <head>
      <meta charset='utf-8'>
      <title>Server-Sent Events demo</title>
      [JScript includes knockout eventsource]
      [JScript wrap {
        var viewModel = { counter : ko.observable("?") };
        ko.applyBindings(viewModel);

        $.eventsource({
          url: 'events/test',
          message: function (data) { viewModel.counter(data.counter); }
        });
      }]
    </head>
    <body>
      Random value:
      <blockquote data-bind="text: counter"></blockquote>
      (should update once a second)
    </body>
  </html>
}]

proc /: {} {
  # Respond to "/" url requests.
  variable html
  wibble pageResponse html [wibble template $html]
}

proc Simulate {} {
  # Generate new change events once a second to all web clients.
  after 1000 [namespace which Simulate]
  set value [round [* 1000000 [rand]]]
  WebSSE propagate test [Ju toJson "counter $value" -dict]
}
