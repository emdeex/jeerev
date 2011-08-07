Jm doc "Launch a TkCon console for an interactive GUI session."

package require tkcon

proc start {args} {
  wm withdraw .

  if {$::tcl_platform(os) eq "Darwin"} {
    tkcon font Monaco 10
  }
  # see http://wiki.tcl.tk/1878 for some more settings
  array set ::tkcon::OPT {
    cols 80
    rows 24
    overrideexit 0
    usehistory 0
  }
  uplevel #0 tkcon::Init [list -rcfile "" -exec "" -root .tkcon]
}
