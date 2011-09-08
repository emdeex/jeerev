Jm doc "Utilities for handling Significant Indentation Formatting."

proc css {text} {
  # ...
}

proc html {text} {
  # Turn HAML-like shorthand into HTML.
  set out ""
  set tree [parse $text]
  if {[string index [lindex $tree 0] 0] eq "!"} {
    append out "<!DOCTYPE html>\n"
    lset tree 0 [string range [lindex $tree 0] 1 end]
  }
  append out [TreeToHtml $tree]
}

proc parse {text} {
  # Parse an indented text into a tree structure.
  set level ""
  dict set stack "" {}
  # the EOF at the end forces dedenting at the end
  foreach line [split [Ju dedent "$text\nEOF"] \n] {
    if {[regexp {^\s*(//.*)?$} $line]} {
      continue ;# skip empty lines and comments
    }
    regexp {^(\s*)(\S.*)} $line - indent rest
    while {$indent < $level} {
      set top [dict get $stack $level]
      dict unset stack $level
      set level [lindex [dict keys $stack] end]
      set last [dict get $stack $level]
      lset last end [concat [lindex $last end] $top]
      dict set stack $level $last
    }
    if {$indent > $level} {
      set level $indent
      dict set stack $level {}
    }
    dict lappend stack $level [list $rest]
  }
  # get rid of the trailing EOF item again
  lrange [dict get $stack ""] 0 end-1
}

proc print {tree {prefix "> "}} {
  # Recursively display a nested tree in indented form.
  foreach x $tree {
    puts "$prefix[lindex $x 0]"
    print [lrange $x 1 end] "$prefix "
  }
}

proc HtmlElements {abbrev {content ""}} {
  # Take the abbreviations on one line and turn them into HTML elements.
  set openTags {}
  set closeTags {}
  foreach x [split $abbrev >] {
    if {[string index $x 0] in {. #}} {
      set x "div$x"
    }
    set tag ""
    set id ""
    set classes {}
    set attrs [lassign [split $x /] x]
    foreach {- y} [regexp -all -inline {([#\.]?[\w\$]+)} $x] {
      switch [string index $y 0] {
        \#      { set id [string range $y 1 end] }
        .       { lappend classes [string range $y 1 end] }
        default { set tag $y}
      }
    }
    lappend closeTags $tag
    if {$id ne ""} {
      append tag " id='" $id "'"
    }
    if {[llength $classes]} {
      append tag " class='" $classes "'"
    }
    if {[llength $attrs]} {
      foreach a $attrs {
        append tag " " [regsub {=(.*)} $a {='\1'}]
      }
    }
    lappend openTags $tag
  }
  if {$content eq "" && [llength $openTags] == 1} {
    return [list "<[lindex $openTags 0] />"]
  }
  set open <[join $openTags ><]>
  set close </[join [lreverse $closeTags] ></]>
  if {$content eq ""} {
    return [list "$open$close"]
  }
  #TODO i18n
  # list $open "\[: [list [string trim $content]]]" $close
  list $open [string trim $content] $close
}

proc HtmlExpand {line hasChildren} {
  # Expand a line once indentation and nesting has been taken care of.
  set open $line
  set close ""
  switch -- [string index $line 0] {
    [ {
      if {$hasChildren} {
        append open " {"
        append close "}]"
      }
    }
    % {
      if {$hasChildren} {
        append open " {"
        append close "% }"
      }
    }
    default {
      if {[regexp {^(.+?):\s(.*)$} $line - divs rest]} {
        set open [join [HtmlElements $divs $rest] ""]
      } else {
        if {$hasChildren} {
          lassign [HtmlElements $line " "] open - close
        } else {
          lassign [HtmlElements $line] open
        }
      }
    }
  }
  list $open $close
}

proc TreeToHtml {tree {prefix ""}} {
  # Recursively convert a parsed SIF tree into HTML.
  set out {}
  foreach x $tree {
    set tail [lassign $x head]
    set children [llength $tail]
    lassign [HtmlExpand $head $children] open close
    if {$open ne ""} {
      if {[string index $open 0] eq "%"} {
        lappend out [string replace $open 1 1 $prefix]
      } else {
        lappend out "$prefix$open"
      }
    }
    if {$children} {
      lappend out [TreeToHtml $tail "$prefix  "]
    }
    if {$close ne ""} {
      if {[string index $close 0] eq "%"} {
        lappend out [string replace $close 1 1 $prefix]
      } else {
        lappend out "$prefix$close"
      }
    }
  }
  join $out \n
}
