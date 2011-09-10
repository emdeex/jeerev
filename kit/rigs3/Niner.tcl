Webserver hasUrlHandlers

variable <NOTES> {
  viewport avoid scaling: http://stackoverflow.com/questions/273671/...
   hiding-safari-user-interface-components-on-iphone
  also works: meta/name=apple-touch-fullscreen/content=yes

  viewport solves scroll-under-footer problem & fails with orientation change:
   meta/name=viewport/content=width=device-width,initial-scale=1.0,
    maximum-scale=1.0,user-scalable=no
  doesn't seem to do anything:
    meta/name=apple-touch-fullscreen/content=yes
    meta/name=apple-mobile-web-app-status-bar-style/content=black-translucent

  KEEP ORIGINAL TEST:
        .row
          .span16.columns#header
            h1: Status Overview
            .nest
              .span8
                h2: haha
                p: Lorem ipsum dolor sit amet, consectetur \
                    adipisicing elit, sed do eiusmod tempor \
                     incididunt ut labore et dolore magna aliqua.
                h2: haha
                p: Lorem ipsum dolor sit amet, consectetur \
                    adipisicing elit, sed do eiusmod tempor \
                     incididunt ut labore et dolore magna aliqua.
                h3: haha
                  p: Lorem ipsum dolor sit amet, consectetur \
                      adipisicing elit, sed do eiusmod tempor \
                       incididunt ut labore et dolore magna aliqua.
                h4: haha
                  p: Lorem ipsum dolor sit amet, consectetur \
                      adipisicing elit, sed do eiusmod tempor \
                       incididunt ut labore et dolore magna aliqua.
                  p: Lorem ipsum dolor sit amet, consectetur \
                      adipisicing elit, sed do eiusmod tempor \
                       incididunt ut labore et dolore magna aliqua.
                h5: haha
                  p: Lorem ipsum dolor sit amet, consectetur \
                      adipisicing elit, sed do eiusmod tempor \
                       incididunt ut labore et dolore magna aliqua.
              .span8
                p: Lorem ipsum dolor sit amet, consectetur \
                    adipisicing elit, sed do eiusmod tempor \
                     incididunt ut labore et dolore magna aliqua. \
                      Ut enim ad minim veniam, quis nostrud exercitation.
                pre: one\ntwo\nthree\n1234567890123456789012345678901234567890
                p: Lorem ipsum dolor sit amet, consectetur adipisicing elit, \
                   sed do eiusmod tempor incididunt ut labore et dolore magna \
                   aliqua. Ut enim ad minim veniam, quis nostrud exercitation \
                   ullamco laboris nisi ut aliquip ex ea commodo consequat. \
                   Duis aute irure dolor in reprehenderit in voluptate velit \
                   esse cillum dolore eu fugiat nulla pariatur. Excepteur sint \
                   occaecat cupidatat non proident, sunt in culpa qui officia \
                   deserunt mollit anim id est laborum.
                p: Lorem ipsum dolor sit amet, consectetur adipisicing elit, \
                   sed do eiusmod tempor incididunt ut labore et dolore magna \
                   aliqua. Ut enim ad minim veniam, quis nostrud exercitation \
                   ullamco laboris nisi ut aliquip ex ea commodo consequat. \
                   Duis aute irure dolor in reprehenderit in voluptate velit \
                   esse cillum dolore eu fugiat nulla pariatur. Excepteur sint \
                   occaecat cupidatat non proident, sunt in culpa qui officia \
                   deserunt mollit anim id est laborum.
        .row
          .span16.columns
            .alert-message.error
              a.close/href=#: &times
              p
                strong: Heads up!
                span: This is aan error message.
          .span15.offset1.columns#data
            h4: haha!
            blockquote: $long

  original #container
        .row
          .span16.columns#header
            h1: [pageTitle $pageId]
            p: This is page [string map {1 ONE 2 TWO 3 THREE \
                                         4 FOUR 5 FIVE 6 SIX \
                                         7 SEVEN 8 EIGHT 9 NINE} $pageId].
}

variable info

proc setup {def} {
  # Set up page definitions for the Niner theme.
  variable info
  set info(owner) [uplevel namespace current]
  dict for {k v} $def {
    set info([string trim $k :]) $v
  }
  dict for {kx vx} $info(pages) {
    dict for {ky vy} $vx {
      dict set info(pageMap) [incr seq] $kx$ky
    }
  }
  # Ju pdict $info(pageMap) pageMap
}

set info(css) {
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
    /* wider apart */
    margin-left: 3px;
    margin-right: 0;
    /* flip to hanging tags */
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
}

set info(js) {
}

variable html [Sif html {
  !html
    head
      meta/charset=utf-8
      meta/name=apple-mobile-web-app-capable/content=yes
      title: [pageTitle $pageId] - [dict get? $info(config) title]
      [JScript includes bootstrap]
      [JScript wrap $info(js)]
      [JScript style $info(css)]
    body>
      #container
        [CallPageHandler $pageId]
      #sider
        //h3: T O P
        ul.tabs.vtabs
          % foreach {target name class} [VerTabLinks $pageId]
            //FIXME can't use ".$class", it adds spurious curly braces
            li>a/class=$class/href=$target>h4: $name
      #footer
        .row
          .span8.columns
            p: this area can be used to display the previous line of status \
               text<br/>and here's some more room for the lastest log message!
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
                li>a/class=$class/href=$target>h4: $name
        #corner>i: OK&nbsp;<br/>OK&nbsp;
}]

proc pageTitle {id} {
  # Look up (or construct) the page title for a given page ID.
  variable info
  set prefix [dict get $info(pageMap) $id]
  set title [Tree at info(pages) $prefix title]
  if {$title eq ""} {
    set title [string trim [string map {: " "} $prefix] " "]
  }
  return $title
}

proc HorTabLinks {id} {
  # Generate the information needed for the horizontal tabs.
  variable info
  set i 0
  foreach x [dict keys $info(pages)] {
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
  variable info
  set group [regsub {:.*} [dict get $info(pageMap) $id] :]
  incr id -1 ;# zero-based is easier for modulo arithmetic
  set i 0
  foreach x [dict keys [dict get $info(pages) $group]] {
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

proc CallPageHandler {id} {
  variable info
  namespace eval $info(owner) [subst [dict get $info(config) handler]]
}

proc /?: {pageId} {
  # Respond to "/" url requests.
  if {$pageId eq ""} { set pageId 1 } ;#FIXME, could be a WebServer regexp bug
  variable info
  variable html
  set color #fcc
  wibble pageResponse html [Webserver expand $html]
}
