Jm doc "Show readings as table in a browser with real-time updates."
Jm needs Webserver WebSSE

if {[app get -collectd 0]} {  
  variable pattern sysinfo:*
  collectd listen sysinfo
} else {
  variable pattern reading:*
  Jm needs Replay

  Drivers locations {
    usb-USB0       house         
    usb-ACM0       office        
    usb-A600dVPp   office        

    RF12-868.5.2   jc-books      
    RF12-868.5.3   lipotest      
    RF12-868.5.4   guest-room
    RF12-868.5.5   living-room    
    RF12-868.5.6   jc-desk       
    RF12-868.5.7   desk
    RF12-868.5.19  lab-bench     
    RF12-868.5.20  lab-bench     
    RF12-868.5.21  lab-bench     
    RF12-868.5.23  upstairs-hall 
    RF12-868.5.24  upstairs-myra 

    KS300          roof
    S300-0         terrace
    S300-1         bathroom
    S300-2         balcony
    EM2-8          lab-outlet
  }
}

variable css {
  body { font-family: Verdana; }
  .main { width: 600px; }
  table { border: 1px solid #ddd; border-collapse: collapse; width: 100%; }
  td { padding: 0 3px; }
  tbody tr:nth-child(even) { background-color: #f8f8f8; }
  /* clean up and re-arrange things a bit */
  .center { text-align: center; }
  .dataTables_length {
    width: 40%; float: left; margin: 3px 0 0 6px;
  }
  .dataTables_filter {
    width: 50%; float: right; text-align: right; margin-right: 6px;
  }
  .dataTables_info {
    width: 80%; float: left; margin: 2px 0 0 6px;
  }
  .dataTables_paginate {
    width: 44px; float: right; text-align: right; margin: 2px 6px 0 0;
  }
  .dataTables_length, .dataTables_filter, .dataTables_info {
    font-weight: normal;
  }
}

variable coffee {
  viewModel =
    tableData: ko.observable []
    update: (data) ->
      t = viewModel.tableData();
      for key, row of data
        t = (e for e in t when e[0] != key)
        row.unshift key
        t.push row
      viewModel.tableData t
  ko.applyBindings viewModel
  $.eventsource url: 'events/table', message: viewModel.update
  $.getJSON 'data.json', viewModel.update
}

variable js {
  var viewModel;
  viewModel = {
    tableData: ko.observable([]),
    update: function(data) {
      var e, key, row, t;
      t = viewModel.tableData();
      for (key in data) {
        row = data[key];
        t = (function() {
          var _i, _len, _results;
          _results = [];
          for (_i = 0, _len = t.length; _i < _len; _i++) {
            e = t[_i];
            if (e[0] !== key) {
              _results.push(e);
            }
          }
          return _results;
        })();
        row.unshift(key);
        t.push(row);
      }
      return viewModel.tableData(t);
    }
  };
  ko.applyBindings(viewModel);
  $.eventsource({
    url: 'events/table',
    message: viewModel.update
  });
  $.getJSON('data.json', viewModel.update);
}

variable datatable {
  dataTable: {
    data: tableData,
    options: {
      bJQueryUI: true,
      aoColumnDefs: [
        { sType: "numeric", aTargets: [1] },
        { sClass: "center", aTargets: [1,2,3,4] },
      ]
    }
  }
}

variable html [Sif html {
  !html
    head
      meta/charset=utf-8
      title: DataTables demo
      [JScript includes ui knockout eventsource datatables kodtb]
      [JScript wrap $js]
      [JScript style $css]
    body
      .main
        table/data-bind=$datatable
          thead>tr
            th/width=38%: Description
            th/width=20%: Value
            th/width=12%: Unit
            th/width=15%: Changed
            th/width=15%: Updated
          tbody
}]

proc /: {} {
  # Respond to "/" url requests.
  variable css
  variable js
  variable datatable
  variable html
  wibble pageResponse html [Webserver expand $html]
}

proc /data.json: {} {
  # Returns a JSON-formatted array with all current values.
  variable pending
  variable pattern
  # The trick is to simulate a change on each state variable and then
  # collect those "pending changes" instead of sending them off as SSE's.
  Propagate ;# flush pending events now, since we're going to clobber $pending
  Ju map TrackState [State keys $pattern]
  wibble pageResponse json [Propagate -collect]
}

proc WEBSSE.SESSION {mode type} {
  # Respond to WebSSE hook events when a session is opened or closed.
  variable pattern
  if {$type eq "table"} {
    set cmd [dict get {open subscribe close unsubscribe} $mode]
    State $cmd $pattern [namespace which TrackState]
  }
}

proc TrackState {param} {
  # Add a result to the pending map for the specified state variable.
  # Will also set up a timer if needed, to flush these results shortly.
  set value [State get $param]
  set fields [split $param :]
  if {[llength $fields] >= 5} {
    # for collectd, simply remove one of the segments and clean up the value
    if {[llength $fields] == 6} {
       regsub {(.*) } $fields {\1-} fields 
    }
    set fields [lreplace $fields 2 2]
    if {[string is double -strict $value] && [round $value] ne $value} {
      set value [format %.5g $value]
    }
  }
  if {[llength $fields] == 4} {
    lassign $fields - where driver what
    dict extract [Drivers getInfo $driver $where $what] \
      desc scale location unit low high
    if {$location eq ""} {
      set location $where
    }
    if {$desc eq ""} {
      set desc "$what ($driver)"
    }
    if {$unit eq "" && $low ne "" && $high ne ""} {
      set unit "$low..$high"
    }
    set scaled [Drivers scaledInt $value $scale]
    dict extract [State getInfo $param] m t
    set item [list $scaled $unit [ShortTime $m] [ShortTime $t]]
    # batch multiple changes into one before propagating them as SSE's
    variable pending
    if {![info exists pending]} {
      after 100 [namespace which Propagate]
    }
    dict set pending "$location $desc" [Ju toJson $item -list]
  }
}

proc ShortTime {secs} {
  if {$secs > 0} {
    set fmt {%H:%M:%S}
    if {$secs < [clock scan 0:00]} {
      set fmt {%b %e}
    }
    clock format $secs -format $fmt
  }
}

proc Propagate {{flag ""}} {
  # Send pending changes off as a JSON object and clear the list.
  variable pending
  set json [Ju toJson [Ju grab pending] -dict -flat]
  if {$flag eq "-collect"} {
    return $json
  }
  WebSSE propagate table $json
}
