Jm doc "A theme for a web site with 3x3 pages and tabs on the bottom + right."
Jm needs WebSSE
Webserver hasUrlHandlers

variable main

proc layout {tree} {
  # Set up page definitions for the Niner theme.
  variable main $tree
  dict set main owner [uplevel namespace current]
  dict for {kx vx} [dict get $main pages:] {
    dict for {ky vy} $vx {
      dict set main pageMap: [incr seq] $kx$ky
      Jm needs {*}[dict get? $vy handler]
    }
  }
}

Ju cachedVar infos . {
  # set up "infos" as a registry for all HTML handlers
  variable infos {}
  dict for {k v} [app hook NINER.INFOS] {
    dict set infos $k $v
  }
}

variable info {
  includes {
    bootstrap eventsource   ui knockout datatables kodtb flot
  }
  css {
    body {
      margin-bottom: 10px;
      padding-left: 8px;
    }
    /* Mark Allen's footer logic: http://mark-allen.net/notes/layout/footer/ */
    #footer {
      position: fixed;
      bottom: 0;
      width: 100%;
      height: 38px;
      background-color: #eee;
      border-top: 1px solid #fcc;
      /* counteract body margin */
      margin-left: -8px;
      padding-left: 8px;
    }
    #footer > * {
      display: inline;
      float: left;
    }
    #sider {
      position: fixed;
      right: 0;
      top: 0;
      width: 23px;
      height: 100%;
      background-color: #eee;
      border-left: 1px solid #fcc;
    }
    #corner {
      position: absolute;
      bottom: 0px;
      right: 8px;
      width: 23px;
      height: 37px;
      text-align: right;
      border: 1px solid #eee;
    }
    .tabs {
      float: right;
      /* flip to hanging tags */
      border-bottom: 0;
    }
    .tabs > li {
      /* flip to hanging tags */
      top: 0;
      bottom: 1px;
    }
    .tabs > li > a {
      /* flip to hanging tags */
      margin-left: 2px;
      margin-right: 0;
      -webkit-border-radius: 0 0 12px 12px;
      -moz-border-radius: 0 0 12px 12px;
      border-radius: 0 0 12px 12px;
      /*XXX color */
      /* centered and fixed width */
      width: 8em;
      text-align: center;
      padding: 0 3px;
      overflow: hidden;
    }
    .tabs .tabOn {
      background-color: white;
      margin-top: -1px;
      border: 1px solid #fcc;
      border-top: 1px solid white;
    }
    .tabOff {
      background-color: #fcc;
    }
    .vtabs {
      position: absolute;
      bottom: 30px;
    }
    .vtabs li a {
      width: 14px;
      height: 5em;
      margin: 3px 0 0 0;
      padding-top: 25px;
      -webkit-border-radius: 0 12px 12px 0; 
      -moz-border-radius: 0 12px 12px 0;
      border-radius: 0 12px 12px 0;
    }
    .vtabs .tabOn {
      background-color: white;
      margin-left: -1px;
      border: 1px solid #fcc;
      border-left: 1px solid white;
    }
    #msg {
      margin-top: 2px;
    }
    #data {
      height: 470px; /*FIXME this depends on display height! */
      overflow: auto;
    }
    #header h1 {
      border-bottom: 1px solid #eee;
    }
    .nest {
      margin-left: -20px;
    }
    #log {
    	margin-top: 5px;
    	font: 11px Courier;
    	overflow: hidden;
    	white-space: nowrap;
    }
  }
  js {
    var lastline = '';
    $.eventsource({
      url: 'events/niner',
      message: function (data) {
        $('#log').html(lastline + '<br/>' + data.sane);
        lastline = data.sane;
      }
    });
  }
  html-sif {
    !html
      head
        meta/charset=utf-8
        meta/name=apple-mobile-web-app-capable/content=yes
        title: [pageTitle $pageId] - [dict get? $main config: title]
        [JScript includes {*}[dict get? $info includes]]
        [JScript wrap [dict get? $info js]]
        [JScript style [dict get? $info css]]
      body>
        #container
          [DispatchToHandler $pageId]
        #sider
          //h3: T O P
          ul.tabs.vtabs
            % foreach {target name class} [VerTabLinks $pageId]
              //FIXME can't use ".$class", it adds spurious curly braces
              li>a/class=$class/href=$target>h5: $name
        #footer
          .row
            .span8.columns
              p#log
              //.alert-message.warning#msg
              //  a.close/href=#: &times
              //  p
              //    strong>Heads up!
              //    span: This is a warning message.
            .span2.columns
              p: We're ONLINE ...<br/>All systems GO!
            .span6.columns
              ul.tabs
                % foreach {target name class} [HorTabLinks $pageId]
                  //FIXME can't use ".$class", it adds spurious curly braces
                  li>a/class=$class/href=$target>h5: $name
          #corner>i: OK&nbsp;<br/>OK&nbsp;
  }
}

proc NINER.INFOS {} {
  variable info
  return $info
}

proc pageTitle {id} {
  # Look up (or construct) the page title for a given page ID.
  variable main
  set prefix [dict get $main pageMap: $id]
  set title [Tree at main pages:$prefix title]
  if {$title eq ""} {
    set title [string trim [string map {: " "} $prefix] " "]
  }
  return $title
}

proc HorTabLinks {id} {
  # Generate the information needed for the horizontal tabs.
  variable main
  set i 0
  foreach x [dict keys [dict get $main pages:]] {
    set target [+ [* $i 3] 1] ;# default target is the top page
    set class tabOff
    if {$i == ($id-1) / 3} {
      incr target [% $id 3] ;# same tab, cycle down vertically
      set class tabOn
    }
    lappend out $target [string toupper [string range $x 0 end-1]] $class
    incr i
  }
  return $out
}

proc VerTabLinks {id} {
  # Generate the information needed for the vertical tabs.
  variable main
  set group [regsub {:.*} [dict get $main pageMap: $id] :]
  incr id -1 ;# zero-based is easier for modulo arithmetic
  set i 0
  foreach x [dict keys [dict get $main pages: $group]] {
    set target [+ [- $id [% $id 3]] $i 1] ;# target stays in same group
    set class tabOff
    if {$i == $id % 3} {
      set class tabOn
    }
    lappend out $target [string toupper [string index $x 0]] $class
    incr i
  }
  return $out
}

proc DispatchToHandler {pageId} {
  variable main
  set owner [dict get $main owner]
  set prefix [dict get $main pageMap: $pageId]
  # determine which handler to use, to lookup the "infos" registration
  set handler [Tree at main pages:$prefix handler]
  if {$handler eq ""} {
    set handler $owner
  }
  ExpandHandlerInfo $pageId $handler
}

proc ExpandHandlerInfo {pageId handler} {
  variable main
  variable infos
  # careful: this "info" is not the variable with the same name!
  set info [dict get $infos [namespace which $handler]]
  # set html up as a cached copy of the sif expansion, if necessary
  if {![dict exists $info html]} {
    dict set info html [Sif html [dict get $info html-sif]]
  }
  # now evaluate the template, with the "main" and "info" vars this in scope 
  Webserver expand [dict get $info html]
}

proc /?: {pageId} {
  # Respond to "/" url requests.
  variable infos
  if {$pageId eq ""} { set pageId 1 } ;#FIXME, could be a WebServer regexp bug
  wibble pageResponse html [ExpandHandlerInfo $pageId Niner]
}

proc WEBSSE.SESSION {mode type} {
  # Respond to WebSSE hook events when a session is opened or closed.
  variable pattern
  if {$type eq "niner"} {
    set cmd [dict get {open add close remove} $mode]
    trace $cmd variable [Log vname sane] write [namespace which Tracer]
  }
}

proc Tracer {a e op} {
  variable nested
  upvar $a v
  # avoid runaway recursion
  if {![info exists nested]} {
    set nested ""
    WebSSE propagate niner [Ju toJson [list $a $v] -dict]
    unset nested
  }
}
