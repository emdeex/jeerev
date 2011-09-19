# Generated, do not edit - $Id$

package provide vlerq 1.8.0

namespace eval View {
  namespace export -clear {[a-z]*}
  namespace ensemble create

# BEGIN code/View.tcl
# High-level data view module

# dispatch "View op v ..." to "View::${type}::^op ..." or else "View::^op ..."
proc Unknown {cmd op v args} {
  # resolve right now iso returning ns inscope to avoid inserting extra level
  set ns [namespace current]::[lindex $v 0]
  return [namespace inscope $ns namespace which ^$op]
}
namespace ensemble create -unknown [namespace code Unknown]

# create a new ref view with the specified size and structure
proc new {rows {meta {ref {}}}} {
  return [View wrap ref [View init data $rows $meta]]
}

# define a view from scratch
proc def {desc {data ""}} {
  set v [View new 0 [desc2meta $desc]]
  View append $v {*}$data
  return $v
}

# true if the view passed in is a meta view
proc ismeta? {v} {
  return [expr {[View meta $v] eq "ref {}"}]
}

# convert a Mk4tcl layout string to a meta-view
proc layout2meta {layout} {
  set meta [View new 0]
  set empty [View deref $meta]
  foreach d $layout {
    if {[llength $d] > 1} {
      lassign $d name subv
      View append $meta $name V [layout2meta $subv]
    } else {
      lassign [split ${d}:S :] name type
      View append $meta $name $type $empty
    }
  }
  return [View destroy $meta] ;# get rid of the modifiable wrapper
}

# convert a Metakit description string to a meta-view
proc desc2meta {d} {
  # adapted from readkit.tcl, converts a Metakit description to a Mk4tcl layout
  set l [string map {] "\}\}" , " "} [regsub -all {(\w+)\s*\[} $d "\{\\1 \{"]]
  return [layout2meta $l]
}

# loop to iterate over items in a view and collect the results
proc loop {v ivar vars body} {
  upvar 1 $ivar i
  foreach x $vars {
    upvar 1 $x _$x
  }
  set o {}
  set n [View size $v]
  for {set i 0} {$i <$n} {incr i} {
    set c -1
    foreach x $vars {
      set _$x [View at $v $i [incr c]]
    }
    set e [catch [list uplevel 1 $body] r]
    switch $e {
      0 - 2 {}
      1     { return -code $e $r }
      3     { return $o }
      4     { continue }
    }
    lappend o $r
  }
  return $o
}

proc OneCol {v {col 0}} {
  set n [View size $v]
  set o {}
  for {set r 0} {$r < $n} {incr r} {
    lappend o [View at $v $r $col]
  }
  return $o
}

proc OneRow {v row {named ""}} {
  if {$named ne ""} {
    set m [OneCol [View meta $v] 0]
  }
  set n [View size [View meta $v]]
  set o {}
  for {set c 0} {$c < $n} {incr c} {
    if {$named ne ""} {
      lappend o [lindex $m $c]
    }
    lappend o [View at $v $row $c]
  }
  return $o
}

# lookup column names
proc ColNum {v argv} {
  set names [OneCol [View meta $v] 0]
  set r {}
  foreach x $argv {
    if {![string is integer -strict $x]} {
      set y [lsearch -exact $names $x]
      if {$y >= 0} {
        set x $y
      }
    }
    lappend r $x
  }
  return $r
}

# general access operator
proc get {v args} {
  if {[llength $args] == 0} {
    lappend args * *
  }
  while {[llength $args] > 0} {
    set args [lassign $args row col]
    switch $row {
      \# {
        return [View size $v]
      }
      @ {
        set v [View meta $v ]
        if {$col eq ""} { return $v }
        set args [linsert $args 0 $col]
        continue
      }
      * {
        switch $col {
          * { return [concat {*}[View loop $v i {} { OneRow $v $i }]] }
          "" { return [View loop $v i {} { OneRow $v $i }] }
          default { return [OneCol $v [ColNum $v $col]] }
        }
      }
      default {
        switch $col {
          * { return [OneRow $v $row] }
          "" { return [OneRow $v $row -named] }
          default { set v [View at $v $row [ColNum $v $col]] }
        }
      }
    }
  }
  return $v
}

# default operators are found via "namespace path"
proc ^deref {v} {
  return $v
}
proc ^destroy {v} {
  # nothing
}
proc ^meta {v} {
  return [lindex $v 1]
}
proc ^size {v} {
  return [lindex $v 2]
}

# "data" meta size col0 col1 ...
namespace eval data {
  namespace path [namespace parent]
  
  proc ^init {- rows meta} {
    set ncols [View size $meta]
    set v [list data [View deref $meta] $rows]
    for {set c 0} {$c < $ncols} {incr c} {
      if {$rows == 0} {
        lappend v {}
      } else {
        switch [View at $meta $c 1] {
          I - L - F - D { set zero 0 }
          V             { set zero [View init data 0 [View at $meta $c 2]] }
          default       { set zero "" }
        }
        lappend v [lrepeat $rows zero]
      }
    }
    return $v
  }

  proc ^at {v row col} {
    return [lindex $v $col+3 $row]
  }
  
  proc ^set/nd {v row col value} {
    return [lset v $col+3 $row $value]
  }
  proc ^replace/nd {v row count w} {
    set last [expr {$row+$count-1}]
    set cols [View size [View meta $v]]
    for {set c 0} {$c < $cols} {incr c} {
      lset v $c+3 [lreplace [lindex $v $c+3] $row $last {*}[OneCol $w $c]]
    }
    return [lset v 2 [expr {[View size $v] - $count + [View size $w]}]]
  }
  proc ^append/nd {v args} {
    set cols [View size [View meta $v]]
    # Rig check {$cols != 0}
    # Rig check {[llength $args] % $cols == 0}
    set i -1
    foreach value $args {
      set offset [expr {[incr i] % $cols + 3}]
      lset v $offset [linsert [lindex $v $offset] end $value]
    }
    return [lset v 2 [llength [lindex $v 3]]]
  }
}

# "ref" handle ?r1 c1 r2 c2 ...?
namespace eval ref {
  namespace path [namespace parent]
  
  namespace eval v {
    variable seq  ;# sequence number to issue new handle names
    variable vwh  ;# array of r/w handles, key is handle, value is real view

    # pre-define the meta-meta view, i.e. {ref {}}
    set vwh() [list data {ref {}} 3 \
                {name type subv} {S S V} [lrepeat 3 {data {ref {}} 0 {} {} {}}]]
  }

  # turn a view into a handle-based modifiable type
  proc ^wrap {- v} {
    set h "v[incr v::seq]ref"
    set v::vwh($h) [View deref $v]
    return [list ref $h]
  }
  
  proc Descend {v} {
    set w $v::vwh([lindex $v 1])
    foreach {r c} [lrange $v 2 end] {
      set w [View at $w $r $c]
    }
    return $w
  }
  
  proc ^deref {v} {
    if {[lindex $v 1] eq ""} {
      return $v ;# can't deref, this is a recursive definition
    }
    return [Descend $v]
  }
  proc ^destroy {v} {
    set oref $v::vwh([lindex $v 1])
    unset v::vwh([lindex $v 1])
    View destroy $oref
    return $oref
  }

  proc ^meta {v} {
    return [View meta [Descend $v]]
  }
  proc ^size {v} {
    return [View size [Descend $v]]
  }
  proc ^at {v row col} {
    set m [View meta $v]
    lappend v $row $col
    # extra test to guard against infinite loop when v is a meta-view
    if {[lindex $v 1] eq "" || [View at $m $col 1] ne "V"} {
      set v [Descend $v]
    }
    return $v
  }
  
  # descend into proper subview, apply the non-destructive change, and unwind
  proc SubChange {op v argv} {
    set value [View $op [Descend $v] {*}$argv]
    while {[llength $v] > 2} {
      set row [lindex $v end-1]
      set col [lindex $v end]
      set v [lrange $v 0 end-2]
      set value [View set/nd [Descend $v] $row $col $value]
    }
    return $value
  }
  proc ^set/nd {v args} {
    return [SubChange set/nd $v $args]
  }
  proc ^set {v args} {
    set v::vwh([lindex $v 1]) [View set/nd $v {*}$args]
  }
  proc ^replace/nd {v args} {
    return [SubChange replace/nd $v $args]
  }
  proc ^replace {v args} {
    set v::vwh([lindex $v 1]) [View replace/nd $v {*}$args]
  }
  proc ^append/nd {v args} {
    return [SubChange append/nd $v $args]
  }
  proc ^append {v args} {
    set v::vwh([lindex $v 1]) [View append/nd $v {*}$args]
  }
}

# "deriv" meta size {op args...} ?...?
namespace eval deriv {
  namespace path [namespace parent]
  
  # child namespace for all getters, these are dispatched to by ^at
  namespace eval getter {}

  # this proc uses introspection to reconstruct the caller's original command
  # must be called with meta-view, size, and any further args to pass to getter
  proc New {meta size args} {
    set cmd [info level -1]
    lset cmd 0 [namespace tail [lindex $cmd 0]]
    return [linsert $args 0 deriv $meta $size $cmd]
  }

  proc ^at {v row col} {
    return [namespace inscope getter [list [lindex $v 3 0] $row $col {*}$v]]
  }
}

# END code/View.tcl
# BEGIN code/View~ops.tcl
# Additional view operators

# return a pretty text representation of a view, without nesting
proc dump {v {maxrows 20}} {
  set n [View size $v]
  if {[View width $v] == 0} { return "  ($n rows, no columns)" }
  set i -1
  foreach x [View names $v] y [View types $v] {
    if {$x eq ""} { set x ? }
    set v2 [View get $v * [incr i]]
    switch $y {
      B       { set s { "[string length $r]b" } }
      V       { set s { "#[View size $r]" } }
      default { set s { } }
    }
    set c {}
    foreach r $v2 {
      lappend c [eval set r $s]
    }
    set c [lrange $c 0 $maxrows-1]
    set w [string length $x]
    foreach z $c {
      if {[string length $z] > $w} { set w [string length $z] }
    }
    if {$w > 50} { set w 50 }
    switch $y {
      B - I - L - F - D - V   { append fmt "  " %${w}s }
      default                 { append fmt "  " %-$w.${w}s }
    }
    append hdr "  " [format %-${w}s $x]
    append bar "  " [string repeat - $w]
    lappend d $c
  }
  set r [list $hdr $bar]
  for {set i 0} {$i < $n} {incr i} {
    if {$i >= $maxrows} break
    set cmd [list format $fmt]
    foreach x $d { lappend cmd [regsub -all {[^ -~]} [lindex $x $i] .] }
    lappend r [eval $cmd]
  }
  if {$i < $n} { lappend r [string map {- .} $bar] }
  ::join $r \n
}

# return a pretty html representation of a view, including nesting
proc html {v {styled 1}} {
  set names [View names $v]
  set types [View types $v]
  set o <table>
  if {$styled} {
    append o {<style type="text/css"><!--\
      table { font: 8.5pt Verdana; }\
      tt table, pre table { border-spacing: 0; border: 1px solid #aaaaaa; }\
      th { background-color: #eeeeee; font-weight: normal; }\
      td { vertical-align: top; }\
      th, td { padding: 0 4px 2px 0; }\
      th.row,td.row { color: #cccccc; font-size: 80%; }\
    --></style>}
  }
  append o \n {<tr><th class="row"></th>}
  foreach x $names {
    if {$x eq ""} { set x ? }
    append o <th><i> $x </i></th>
  }
  append o </tr>\n
  set n [View size $v]
  for {set r 0} {$r < $n} {incr r} {
      append o {<tr><td align="right" class="row">} $r </td>
      set i -1
      foreach x $names y $types val [View get $v $r *] {
          switch $y {
              b - B   { set z [string length $val]b }
              v - V   { set z \n[View html $val 0]\n }
              default { 
                  set z [string map {& &amp\; < &lt\; > &gt\;} $val] 
              }
          }
          switch $y {
              s - S - v - V { append o {<td>} }
              default { append o {<td align="right">} }
          }
          append o $z </td>
      }
      append o </tr>\n
  }
  append o </table>
}

# define a view with one int column
proc ints {data} {
  #TODO optional arg flags column name lookup mode, to convert any column names
  return [View def :I $data]
}

# shorthand to get the number of columns
proc width {v} {
  return [View size [View meta $v]]
}

# shorthand to get the list of names
proc names {v} {
  return [View get $v @ * 0]
}

# shorthand to get the list of types
proc types {v} {
  return [View get $v @ * 1]
}

# return a structure description without column names
proc structure {v} {
  if {![ismeta? $v]} {
    set v [View meta $v]
  }
  set desc [View loop $v - {x type subv} {
    if {$type eq "V"} {
      set s [View structure $subv]
      if {$s ne ""} {
        return "($s)"
      }
    }
    return $type
  }]
  return [join $desc ""]
}

# map rows of v using col 0 of w
proc rowmap {v w} {
  return [deriv::New [View meta $v] [View size $w]]
}
proc deriv::getter::rowmap {row col - meta size cmd} {
  set v [lindex $cmd 1]
  set r [View at [lindex $cmd 2] $row 0]
  if {$r < 0} {
    set r [View at [lindex $cmd 2] $row+$r 0]
  }
  return [View at $v [expr {$r % [View size $v]}] $col]
}

# map columns of v using col 0 of w
proc colmap {v w} {
  return [deriv::New [View rowmap [View meta $v] $w] [View size $v]]
}
proc deriv::getter::colmap {row col - meta size cmd} {
  return [View at [lindex $cmd 1] $row [View at [lindex $cmd 2] $col 0]]
}

# cancatenate any number of views, which must all have the same structure
#TODO verify structure compat (maybe also "narrow down", similar to pair op?)
proc plus {v args} {
  set counts [View size $v]
  foreach a $args {
    lappend counts [View size $a]
  }
  return [deriv::New [View meta $v] [tcl::mathop::+ {*}$counts] $counts]
}
proc deriv::getter::plus {row col - meta size cmd counts} {
  set i 0
  foreach n $counts {
    incr i
    if {$row < $n} {
      return [View at [lindex $cmd $i] $row $col]
    }
    set row [expr {$row - $n}]
  }
}

# put views "next" to each other, result size is size of smallest one
proc pair {v args} {
  set size [View size $v]
  set metas [list [View meta $v]]
  set widths [View width $v]
  foreach a $args {
    set size [expr {min($size,[View size $a])}]
    set m [View meta $a]
    lappend metas $m
    lappend widths [View size $m]
  }
  return [deriv::New [View plus {*}$metas] $size $widths]
}
proc deriv::getter::pair {row col - meta size cmd widths} {
  set i 0
  foreach n $widths {
    incr i
    if {$col < $n} {
      return [View at [lindex $cmd $i] $row $col]
    }
    set col [expr {$col - $n}]
  }
}

# iota and step generator
proc step {count {off 0} {step 1} {rate 1}} {
  return [deriv::New [desc2meta :I] $count $off $step $rate]
}
proc deriv::getter::step {row col - meta size cmd off step rate} {
  return [expr {$off + $step * ($row / $rate)}]
}

# reverse the row order
proc reverse {v} {
  set rows [View size $v]
  return [View rowmap $v [View step $rows [expr {$rows-1}] -1]]
}

# return the first n rows
proc first {v n} {
  return [View pair $v [View new $n]]
}

# return the last n rows
proc last {v n} {
  return [View reverse [View first [View reverse $v] $n]]
}

# repeat each row x times
proc spread {v x} {
  set n [View size $v]
  return [View rowmap $v [View step [expr {$n * $x}] 0 1 $x]]
}

# repeat the entire view x times
proc times {v x} {
  return [View rowmap $v [View step [expr {[View size $v] * $x}]]]
}

# cartesian product
proc product {v w} {
  return [View pair [View spread $v [View size $w]] \
                    [View times $w [View size $v]]]
}

# return a set of ints except those listed in the map
proc omitmap {v n} {
  set o {}
  foreach x [View get $v * 0] {
    dict set o $x ""
  }
  set m {}
  for {set i 0} {$i < $n} {incr i} {
    if {![dict exists $o $i]} {
      lappend m $i
    }
  }
  return [View ints $m]
}

# omit the specified rows from the view
proc omit {v w} {
  return [View rowmap $v [View omitmap $w [View size $v]]]
}

# a map with indices of only the first unique rows
proc uniqmap {v} {
  set m {}
  set n [View size $v]
  for {set i 0} {$i < $n} {incr i} {
    set r [View get $v $i *]
    if {![dict exists $m $r]} {
      dict set m $r $i
    }
  }
  return [View ints [dict values $m]]
}

# return only the unique rows
proc unique {v} {
  return [View rowmap $v [View uniqmap $v]]
}

# relational projection
proc project {v cols} {
  return [View unique [View colmap $v [View ints [ColNum $v $cols]]]]
}

# create a view with same structure but no content
proc clone {v} {
  return [View new 0 [View meta $v]]
}

# collect indices of identical rows
proc RowGroups {v} {
  set m {}
  set n [View size $v]
  for {set i 0} {$i < $n} {incr i} {
    dict lappend m [View get $v $i *] $i
  }
  return $m
}

# indices of all rows in v which are also in w
proc isectmap {v w} {
  set g [RowGroups $w]
  set m {}
  set n [View size $v]
  for {set i 0} {$i < $n} {incr i} {
    set r [View get $v $i *]
    if {[dict exists $g $r]} {
      lappend m $i
    }
  }
  return [View ints $m]
}

# set intersection
proc intersect {v w} {
  return [View rowmap $v [View isectmap $v $w]]
}

# indices of all rows in v which are not in w
proc exceptmap {v w} {
  return [View omitmap [View isectmap $v $w] [View size $v]]
}

# set exception
proc except {v w} {
  return [View rowmap $v [View exceptmap $v $w]]
}

# set union
proc union {v w} {
  return [View plus $v [View except $w $v]]
}

# return a groupmap
proc groupmap {v {name ""} {desc ""} {v2 ""} {ovar ""}} {
  append desc :I
  set g [RowGroups $v]
  set m [View new 0]
  View append $m $name V [desc2meta $desc]
  set w [View new 0 $m]
  set i -1
  dict for {x y} $g {
    View append $w [View def $desc $y]
    dict set g $x [incr i]
  }
  if {$ovar ne ""} {
    set o {}
    set e [View size $v]
    set n [View size $v2]
    for {set i 0} {$i < $n} {incr i} {
      set r [View get $v2 $i *]
      if {[dict exists $g $r]} {
        lappend o [dict get $g $r]
      } else {
        lappend o $e
      }
    }
    # return the map view with v2 lookups
    uplevel [list set $ovar [View ints $o]]
    # add an empty subview for rows in v2 which are not in v
    View append $w [View def $desc {}]
  }
  return $w
}

# return a grouped view
proc group {v cols {name ""}} {
  set cmap [View ints [ColNum $v $cols]]
  set keys [View colmap $v $cmap]
  set rest [View colmap $v [View omitmap $cmap [View width $v]]]
  set gmap [groupmap $keys]
  set head [View ints [View loop $gmap - x { View at $x 0 0 }]]
  set meta [View new 0]
  View append $meta $name V [View meta $rest]
  set nest [deriv::New $meta [View size $gmap] $rest $gmap]
  return [View pair [View rowmap $keys $head] $nest]
}
proc deriv::getter::group {row col - meta size cmd rest gmap} {
  return [View rowmap $rest [View at $gmap $row 0]]
}

# ungroup a view on specified column
proc ungroup {v col} {
  set col [ColNum $v $col]
  set m {}
  set n [View size $v]
  for {set i 0} {$i < $n} {incr i} {
    set k [View size [View at $v $i $col]]
    if {$k > 0} {
      lappend m $i
      for {set j 1} {$j < $k} {incr j} {
        lappend m -$j
      }
    }
  }
  set smap [View ints $m]
  set rest [View colmap $v [View omitmap [View ints $col] [View width $v]]]
  set subs [View colmap $v [View ints $col]]
  set meta [View at [View meta $subs] 0 2]
  set flat [deriv::New $meta [View size $smap] $smap $subs]
  return [View pair [View rowmap $rest $smap] $flat]
}
proc deriv::getter::ungroup {row col - meta size cmd smap subs} {
  set pos [View at $smap $row 0]
  if {$pos >= 0} {
    set off 0
  } else {
    set off [expr {-$pos}]
    set pos [View at $smap [expr {$row + $pos}] 0]
  }
  return [View at [View at $subs $pos 0] $off $col]
}

# join operator
proc ^join {v w {name ""}} {
  #TODO don't compare subview columns for now
  set vn [View colmap [View meta $v] [View ints {0 1}]]
  set wn [View colmap [View meta $w] [View ints {0 1}]]
  set vi [View isectmap $vn $wn]
  set wi [View isectmap $wn $vn]
  set vkeys [View colmap $v $vi]
  set wkeys [View colmap $w $wi]
  #set vrest [View colmap $v [View omitmap $vi [View size $vn]]]
  set wrest [View colmap $w [View omitmap $wi [View size $wn]]]
  set gmap [View groupmap $wkeys $name "" $vkeys omap]
  set meta [View new 0]
  View append $meta $name V [View meta $wrest]
  set nest [deriv::New $meta [View size $omap] $wrest $gmap $omap]
  return [View pair $v $nest]
}
proc deriv::getter::^join {row col - meta size cmd rest gmap omap} {
  return [View rowmap $rest [View at $gmap [View at $omap $row 0] 0]]
}

# inner join
proc ijoin {v w} {
  set x [View join $v $w]
  return [View ungroup $x [expr {[View width $x] - 1}]]
}

# make a shallow copy, return as new var view
proc copy {v} {
  set o [View new 0 [View meta $v]]
  set n [View size $v]
  for {set i 0} {$i < $n} {incr i} {
    View append $o {*}[View get $v $i *]
  }
  return $o
}

# rename columns
proc ^rename {v args} {
  #set m [View wrap mut [View meta $v]] ;# uses a mutable view
  set m [View copy [View meta $v]] ;# avoids dependency on View~mut
  foreach {x y} $args {
    View set $m [ColNum $v $x] 0 $y
  }
  return [deriv::New $m [View size $v]]
}
proc deriv::getter::^rename {row col - meta size cmd} {
  return [View at [lindex $cmd 1] $row $col]
}

# blocked views
proc blocked {v} {
  #Rig check {[View width $v] == 1}
  set tally 0
  set offsets {}
  set rows [View size $v]
  for {set i 0} {$i < $rows} {incr i} {
    lappend offsets [incr tally [View size [View at $v $i 0]]]
  }
  set meta [View at [View meta $v] 0 2]
  return [deriv::New $meta $tally $offsets]
}
proc deriv::getter::blocked {row col - meta size cmd offsets} {
  set v [lindex $cmd 1]
  set block -1
  foreach o $offsets {
    if {[incr block] + $o >= $row} break
  }
  if {$row == $block + $o} {
    set row $block
    set block [expr {[View size $v] - 1}]
  } elseif {$block > 0} {
    set row [expr {$row - $block - [lindex $offsets $block-1]}]
  }
  return [View at [View at $v $block 0] $row $col]
}

# END code/View~ops.tcl
# BEGIN code/View~readkit.tcl
# View adapter for readkit, a Metakit reader in Tcl (included)

# "readkit" meta path
namespace eval readkit {
  namespace path [namespace parent]
  
  variable seq  ;# used to generate db names
  
  # open a datafile and return a storage view, has 1 row with all views on file
  proc ^open {- args} {
    variable seq
    set db "db[incr seq]readkit"
    Readkit dbopen $db {*}$args
    set m [View layout2meta [Readkit dblayout $db]]
    set v [View new 1 $m]
    set n [View size $m]
    for {set i 0} {$i < $n} {incr i} {
      View set $v 0 $i [list readkit [View at $m $i 2] $db.[View at $m $i 0]]
    }
    return $v
  }
  
  proc ^size {v} {
    return [Readkit vlen [Readkit access [lindex $v 2]]]
  }
  proc ^at {v row col} {
    set name [View at [lindex $v 1] $col 0]
    if {[lindex $v 1] ne "" && [View at [lindex $v 1] $col 1] eq "V"} {
      return [list readkit [View at [lindex $v 1] $col 2] \
                                    [lindex $v 2]!$row.$name]
    }
    return [Readkit::Mvec [Readkit access [lindex $v 2]!$row] $name]
  }
}

# Metakit datafile reader in Tcl
namespace eval readkit::Readkit {
  namespace export -create {[a-z]*}
  namespace ensemble create

  # Mmap and Mvec primitives in pure Tcl (a C version is present in critlib)

  namespace eval v {
    array set mmap_data {}
    array set mvec_shifts {
      - -1    0 -1
      1  0    2  1    4  2    8   3
      16 4   16r 4
      32 5   32r 5   32f 5   32fr 5
      64 6   64r 6   64f 6   64fr 6
    }
  }

  proc Mmap {fd args} {
    upvar 0 v::mmap_data($fd) data
    # special case if fd is the name of a variable (qualified or global)
    if {[uplevel #0 [list info exists $fd]]} {
      upvar #0 $fd var
      set data $var
    }
    # cache a full copy of the file to simulate memory mapping
    if {![info exists data]} {
      set pos [tell $fd]
      seek $fd 0 end
      set end [tell $fd]
      seek $fd 0
      set trans [fconfigure $fd -translation]
      fconfigure $fd -translation binary
      set data [read $fd $end]
      fconfigure $fd -translation $trans
      seek $fd $pos
    }
    set total [string length $data]
    if {[llength $args] == 0} {
      return $total
    }
    lassign $args off len
    if {$len < 0} {
      set len $total
    }
    if {$len < 0 || $len > $total - $off} {
      set len [expr {$total - $off}]
    }
    binary scan $data @${off}a$len s
    return $s
  }

  proc Mvec {v args} {
    lassign $v mode data off len
    if {[info exists v::mvec_shifts($mode)]} {
      # use MvecGet to access elements
      set shift $v::mvec_shifts($mode)
      if {[llength $v] < 4} {
        set len $off
      }
      set get [list MvecGet $shift $v *]
    } else {
      # virtual mode, set to evaluate script
      set shift ""
      set len [lindex $v end]
      set get $v
    }
    # try to derive vector length from data length if not specified
    if {$len eq "" || $len < 0} {
      set len 0
      if {$shift >= 0} {
        if {[llength $v] < 4} {
          set n [string length $data] 
        } else {
          set n [Mmap $data]
        }
        set len [expr {($n << 3) >> $shift}]
      }
    }
    set nargs [llength $args]
    # with just a varname as arg, return info about this vector
    if {$nargs == 0} {
      if {$shift eq ""} {
        return [list $len {} $v]
      }
      return [list $len $mode $shift]
    }
    lassign $args pos count pred cond
    # with an index as second arg, do a single access and return element
    if {$nargs == 1} {
      return [uplevel 1 [lreplace $get end end $pos]]
    }
    if {$count < 0} {
      set count $len
    }
    if {$count > $len - $pos && $shift != -1} {
      set count [expr {$len - $pos}]
    }
    if {$nargs == 4} {
      upvar $pred x
    }
    set r {}
    incr count $pos
    # loop through specified range to build result vector
    # with four args, used that as predicate function to filter
    # with five args, use fourth as loop var and apply fifth as condition
    for {set x $pos} {$x < $count} {incr x} {
      set y [uplevel 1 [lreplace $get end end $x]]
      switch $nargs {
        3 { if {![uplevel 1 [list $pred $v $x $y]]} continue }
        4 { if {![uplevel 1 [list expr $cond]]} continue }
      }
      lappend r $y
    }
    return $r
  }

  proc MvecGet {shift desc index} {
    lassign $desc mode data off len
    switch -- $mode {
      - { return $index }
      0 { return $data }
    }
    if {[llength $desc] < 4} {
      set off [expr {($index << $shift) >> 3}] 
    } else {
      # don't load more than 8 bytes from the proper offset
      incr off [expr {($index << $shift) >> 3}]
      set data [Mmap $data $off 8]
      set off 0
    }
    switch -- $mode {
      1 {
        binary scan $data @${off}c value
        return [expr {($value>>($index&7))&1}]
      }
      2 {
        binary scan $data @${off}c value
        return [expr {($value>>(($index&3)<<1))&3}]
      }
      4 {
        binary scan $data @${off}c value
        return [expr {($value>>(($index&1)<<2))&15}]
      }
      8    { set w 1; set f c }
      16   { set w 2; set f s }
      16r  { set w 2; set f S }
      32   { set w 4; set f i }
      32r  { set w 4; set f I }
      32f  { set w 4; set f r }
      32fr { set w 4; set f R }
      64   { set w 8; set f w }
      64r  { set w 8; set f W }
      64f  { set w 8; set f q }
      64fr { set w 8; set f Q }
    }
    #TODO reverse endianness on big-endian platforms not verified
    # may need to use a string map to reverse upper/lower for 16+ sizes
    binary scan $data @$off$f value
    return $value
  }

  # Decoder for Metakit datafiles in Tcl
  # requires Mmap/Mvec primitives

  namespace eval v {
    variable data
    variable seqn
    variable zero
    variable curr
    variable byte
    variable info ;# array
    variable node ;# array
    variable dbs  ;# array
  }

  proc Byte_seg {off len} {
    incr off $v::zero
    return [Mmap $v::data $off $len]
  }

  proc Int_seg {off cnt} {
    set vec [list 32r [Byte_seg $off [expr {4*$cnt}]]]
    return [Mvec $vec 0 $cnt]
  }

  proc Get_s {len} {
    set s [Byte_seg $v::curr $len]
    incr v::curr $len
    return $s
  }

  proc Get_v {} {
    set v 0
    while 1 {
      set char [Mvec $v::byte $v::curr]
      incr v::curr
      set v [expr {$v*128+($char&0xff)}]
      if {$char < 0} {
        return [incr v -128]
      }
    }
  }

  proc Get_p {rows vs vo} {
    upvar $vs size $vo off
    set off 0
    if {$rows == 0} {
      set size 0 
    } else {
      set size [Get_v]
      if {$size > 0} {
        set off [Get_v]
      }
    }
  }

  proc Header {{end ""}} {
    set v::zero 0
    if {$end eq ""} {
      set end [Mmap $v::data]
    }
    set v::byte [list 8 $v::data $v::zero $end]
    lassign [Int_seg [expr {$end-16}] 4] t1 t2 t3 t4
    set v::zero [expr {$end-$t2-16}]
    incr end -$v::zero
    set v::byte [list 8 $v::data $v::zero $end]
    lassign [Int_seg 0 2] h1 h2
    lassign [Int_seg [expr {$h2-8}] 2] e1 e2
    set v::info(mkend) $h2
    set v::info(mktoc) $e2
    set v::info(mklen) [expr {$e1 & 0xffffff}]
    set v::curr $e2
  }

  proc Layout {fmt} {
    regsub -all { } $fmt "" fmt
    regsub -all {(\w+)\[} $fmt "{\\1 {" fmt
    regsub -all {\]} $fmt "}}" fmt
    regsub -all {,} $fmt " " fmt
    return $fmt
  }

  proc DescParse {desc} {
    set names {}
    set types {}
    foreach x $desc {
      if {[llength $x] == 1} {
        lassign [split $x :] name type
        if {$type eq ""} {
          set type S } 
      } else {
        lassign $x name type
      }
      lappend names $name
      lappend types $type
    }
    return [list $names $types]
  }

  proc NumVec {rows type} {
    Get_p $rows size off
    if {$size == 0} {
      return {0 0}
    }
    set w [expr {int(($size<<3)/$rows)}]
    if {$rows <= 7 && 0 < $size && $size <= 6} {
      set widths {
        {8 16  1 32  2  4}
        {4  8  1 16  2  0}
        {2  4  8  1  0 16}
        {2  4  0  8  1  0}
        {1  2  4  0  8  0}
        {1  2  4  0  0  8}
        {1  2  0  4  0  0}
      }
      set w [lindex [lindex $widths [expr {$rows-1}]] [expr {$size-1}]]
    }
    if {$w == 0} {
      error "NumVec?"
    }
    switch $type F { set w 32f } D { set w 64f }
    incr off $v::zero
    return [list $w $v::data $off $rows]
  }

  proc Lazy_str {self rows type pos sizes msize moff index} {
    set soff {}
    for {set i 0} {$i < $rows} {incr i} {
      set n [Mvec $sizes $i]
      lappend soff $pos
      incr pos $n
    }
    if {$msize > 0} {
      set slen [Mvec $sizes 0 $rows]
      set v::curr $moff
      set limit [expr {$moff+$msize}]
      for {set row 0} {$v::curr < $limit} {incr row} {
        incr row [Get_v]
        Get_p 1 ms mo
        set soff [lreplace $soff $row $row $mo]
        set slen [lreplace $slen $row $row $ms]
      }
      set sizes [list lindex $slen $rows]
    }
    if {$type eq "S"} {
      set adj -1
    } else {
      set adj 0
    }
    set v::node($self) [list Get_str $soff $sizes $adj $rows]
    return [Mvec $v::node($self) $index]
  }

  proc Get_str {soff sizes adj index} {
    set n [Mvec $sizes $index]
    return [Byte_seg [lindex $soff $index] [incr n $adj]]
  }

  proc Lazy_sub {self desc size off rows index} {
    set v::curr $off
    lassign [DescParse $desc] names types
    set subs {}
    for {set i 0} {$i < $rows} {incr i} {
      if {[Get_v] != 0} {
        error "Lazy_sub?"
      }
      lappend subs [Prepare $types]
    }
    set v::node($self) [list Get_sub $names $subs $rows]
    return [Mvec $v::node($self) $index]
  }

  proc Get_sub {names subs index} {
    lassign [lindex $subs $index] rows handlers
    return [list Get_view $names $rows $handlers $rows]
  }

  proc Prepare {types} {
    set r [Get_v]
    set handlers {}
    foreach x $types {
      set n [incr v::seqn]
      lappend handlers $n
      switch $x {
        I - L - F - D {
          set v::node($n) [NumVec $r $x]
        }
        B - S {
          Get_p $r size off
          set sizes {0 0}
          if {$size > 0} {
            set sizes [NumVec $r I]
          }
          Get_p $r msize moff
          set v::node($n) [list Lazy_str $n $r $x $off $sizes $msize $moff $r]
        }
        default {
          Get_p $r size off
          set v::node($n) [list Lazy_sub $n $x $size $off $r $r]
        }
      }
    }
    return [list $r $handlers]
  }

  proc Get_view {names rows handlers index} {
    return [list Get_prop $names $rows $handlers $index [llength $names]]
  }

  proc Get_prop {names rows handlers index ident} {
    set col [lsearch -exact $names $ident]
    if {$col < 0} {
      error "unknown property: $ident"
    }
    set h [lindex $handlers $col]
    return [Mvec $v::node($h) $index]
  }

  proc dbopen {db file {fd ""}} {
    # open datafile, stores datafile descriptors and starts building tree
    if {$db eq ""} {
      set r {}
      foreach {k v} [array get v::dbs] {
        lappend r $k [lindex $v 0]
      }
      return $r
    }
    if {$fd eq ""} {
      set v::data [open $file]
    } else {
      set v::data $fd
    }
    set v::seqn 0
    Header
    if {[Get_v] != 0} {
      error "dbopen?"
    }
    set desc [Layout [Get_s [Get_v]]]
    lassign [DescParse $desc] names types
    set root [Get_sub $names [list [Prepare $types]] 0]
    set v::dbs($db) [list $file x$v::data $desc [Mvec $root 0]]
    if {$fd eq ""} {
      #close $v::data
    }
    return $db
  }

  proc dbclose {db} {
    # close datafile, get rid of stored info
    unset v::dbs($db)
    unset v::mmap_data($v::data)
  }

  proc dblayout {db} {
    # return structure description
    return [lindex $v::dbs($db) 2]
  }

  proc Tree {db} {
    # datafile selection, first step in access navigation loop
    return [lindex $v::dbs($db) 3]
  }

  proc access {spec} {
    # this is the main access navigation loop
    set s [split $spec ".!"]
    set x [list Tree [array size v::dbs]]
    foreach y $s {
      set x [Mvec $x $y]
    }
    return [namespace current]::$x
  }

  proc vnames {view} {
    # return a list of property names
    return [lindex $view 1]
  }

  proc vlen {view} {
    # return the number of rows in this view
    if {[namespace tail [lindex $view 0]] ne "Get_view"} {
      puts 1-$view
      puts 2-<[namespace tail [lindex $view 0]]>
      error "vlen?"
    }
    return [lindex $view 2]
  }
}

# END code/View~readkit.tcl
}

# End of generated code.
