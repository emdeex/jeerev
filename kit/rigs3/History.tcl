Jm doc "Manage historical data storage."
Webserver hasUrlHandlers

variable collector  ;# key = param, value = list of values to aggregate

Ju cachedVar lastTime - {
  variable lastTime 0
}

proc APP.READY {} {
  variable fd [open [Stored path history.log] a+]
  chan configure $fd -buffering none  
  State subscribe * [namespace which StateChanged]
}

proc group {pattern args} {
  # Define a bucket group for a specific set of state variables.
  variable buckets
  # puts "  $pattern"
  foreach x $args {
    lassign [split $x /] range step
    set step [Ju asSeconds $step]
    set range [Ju asSeconds $range]
    dict lappend buckets($pattern) $step $range
    # puts "    step $step range $range count [/ $range $step]"
  }
}

proc query {param args} {
  # Return the requested historical data as list of num/min/max/sum values.
  upvar [namespace current]::collector($param) myData
  if {![info exists myData]} {
    SetupCollector $param 0 [<< 1 100] ;# -999999999 999999999
  }
  set chain [dict get $myData chain]
  if {$chain ne ""} {
    $chain select {*}$args
  }
}

proc /query/**: {args} {
  # Web interface to perform arbitrary queries on historical data.
  dict set response header content-type {"" text/plain charset utf-8}
  dict set response content [query {*}[split $args /]]
}

proc StateChanged {param} {
  # Called on each state variable change to collect historical data.
  dict extract [State getInfo $param] v t
  # only keep track of numeric data
  if {[string is double -strict $v]} {
    LogValue $param $v $t
    CollectValue $param $v $t
  }
}

proc LogValue {param value time} {
  # Save a new parameter value to the history log file.
  variable fd
  variable lastTime
  set id [Stored mapId history $param]
  # store time differences (or the full time, when starting up)
  chan puts $fd [list $id $value [- $time $lastTime]]
  set lastTime $time
}

proc CollectValue {param value time} {
  # Collect and aggregate values according to the different buckets we have.
  upvar [namespace current]::collector($param) myData
  if {![info exists myData]} {
    SetupCollector $param 0 [<< 1 100] ;# -999999999 999999999
  }
  set slot [/ $time [dict get $myData minStep]]
  if {$slot ne [dict get $myData slot]} {
    FlushSlot $param
    dict set myData slot $slot
  }
  dict lappend myData values $value
}

proc SetupCollector {param low high} {
  # Create a bucket chain and set up the in-memory info needed to collect data.
  variable buckets
  upvar [namespace current]::collector($param) myData
  set myData {minStep 9999 chain {} slot -1 values {}}
  # figure out which buckets to set up for this parameter
  foreach {pattern bucketlist} [array get buckets] {
    if {[string match $pattern $param]} {
      # set up buckets in decreasing step size
      set prevStep ""
      set prevObj ""
      foreach {s r} [lsort -stride 2 -dec -int $bucketlist] {
        if {$s < [dict get $myData minStep]} {
          dict set myData minStep $s
        }
        # each larger step must be an exact multiple of the previous one
        Ju assert {$prevStep eq "" || $prevStep % $s == 0 && $prevStep > $s}
        set obj [Bucket new $param $s $r $low $high $prevObj $prevStep]
        set prevStep $s
        set prevObj $obj
      }
      dict set myData chain $obj
      return
    }
  }
}

proc FlushSlot {param} {
  # Called on each change of time slot to send of all aggregated data so far.
  upvar [namespace current]::collector($param) myData
  set slot [dict get $myData slot]
  set values [dict get $myData values]
  if {[llength $values] > 0} {
    set chain [dict get $myData chain]
    if {$chain ne ""} {
      $chain aggregate [* $slot [dict get $myData minStep]] $values
      #TODO propagate down (needs bucket select code)
    }
  }
  dict set myData values {}
}

Ju classDef Bucket {
  Jm doc "Each Bucket object manages one aggregating bucket for one parameter."
  
  variable param step range count child chstep type filler width \
            prevSecs fname currSlot
  
  constructor {bparam bstep brange blow bhigh bchild bchstep} {
    # Set up instance variables and create a fresh datafile if necessary.
    set param $bparam
    set id [Stored mapId hist-data $param]
    set step $bstep
    set range $brange
    set count [/ $brange $bstep]
    set child $bchild
    set chstep $bchstep
    my SetType $blow $bhigh
    set prevSecs 0
    file mkdir [Stored path hist-data]
    set fname [Stored path hist-data/$id-$step-$count-$type]
    if {![file exists $fname]} {
      my CreateFile
    }
    my RecoverSlot
  }
  
  method CreateFile {} {
    # Fill a new file with empty slots. This file won't grow further during use.
    set fd [my Open a+]
    # don't go back in time more than the total range we're storing
    set firstSlot [/ [- [clock seconds] $range] $step]
    set filler [binary format $type 0 0 0 0]
    set emptySlots [string repeat $filler $count]
    append emptySlots [binary format cI -1 $firstSlot]
    chan puts -nonewline $fd $emptySlots
    chan close $fd
  }
  
  method SetType {low high} {
    # Determine the datatypes and sizes/widths to use for each slot.
    if {[string first . $low$high] >= 0} {
      set type crrr
    } else {
      set type cqqq
      foreach {b t} { 7 cccs 15 cssi 31 ciiw 63 cwwq } {
        set limit [<< 1 $b]
        if {-$limit < $low && $high < $limit} {
          set type $t
          break
        }
      }
    }
    set filler [binary format $type  0 0 0 0]
    # set width 0
    # foreach x [split $type ""] {
    #   incr width [string map {c 1 s 2 i 4 w 8 r 8} $x]
    # }
    set width [string length $filler]
    Ju assert {$width >= 5}
  }
  
  method sameSlot {t1 t2} {
    # Are both times in the same slot, i.e. bucket?
    expr {$t1 / $step == $t2 / $step}
  }
    
  method ToBinary {slot values pass} {
    # Convert a set of values to the binary format stored on file.
    if {$pass} {
      lassign $values num min max sum
    } else {
      set num [llength $values]
      set min [min {*}$values]
      set max [max {*}$values]
      set sum [+ {*}$values]
    }
    puts " : $num $min $max $sum ($param)"
    binary format ${type}cI $num $min $max $sum -1 $slot
  }
  
  method aggregate {secs values {pass 0}} {
    # Aggregate and store new values into the proper slot.
    set slot [/ $secs $step]
    Ju assert {$slot >= $currSlot}
    set fd [my Open]
    # don't leave gaps, fill empty slots between last one and new one
    while {$slot != $currSlot} {
      my Store $fd [incr currSlot] $filler
    }
    my Store $fd $slot [my ToBinary $slot $values $pass]
    chan close $fd
  }
  
  method Open {{mode r+}} {
    # Open the associated datafile.
    set fd [open $fname $mode]
    chan configure $fd -translation binary -buffering none
    return $fd
  }
  
  method Store {fd slot bytes} {
    # Store some binary data in the specified slot.
    chan seek $fd [* [% $slot $count] $width]
    chan puts -nonewline $fd $bytes
    set secs [* $slot $step]
    if {$child ne "" && $prevSecs != 0 && ![$child sameSlot $secs $prevSecs]} {
      my SendToChild $prevSecs
    }
    set prevSecs $secs
  }
  
  method RecoverSlot {} {
    # Scan through an existing datafile to determine the last slot written.
    set fd [my Open r]
    while true {
      set bytes [read $fd $width]
      Ju assert {[string length $bytes] >= 5}
      binary scan $bytes cI tag slot
      if {$tag == -1} {
        # puts "recovered: [clock format [* $slot $step]] ($fname)"
        set currSlot $slot
        break
      }
    }
    chan close $fd
  }
  
  method select {selFrom selStep selCount} {
    # Return selected data, delegating as much as possible to child bucket(s).
    Ju assert {$selFrom % $selStep == 0}
    set results {}
    # if larger step than ours, then first try to delegate to the child bucket
    if {$selStep > $step && $child ne ""} {
      set results [$child select $selFrom $selStep $selCount]
      incr selFrom [* [llength $results] $selStep]
      incr selCount [- [llength $results]]
    }
    # can only respond to requests which use a multiple of our step size
    if {$selStep % $step == 0} {
      set fd [my Open r]
      set multiple [/ $selStep $step]
      set limit [* [+ $currSlot 1] $step]
      # collect values for each request step until we run past what's stored
      while {$selCount > 0 && $selFrom < $limit} {
        lappend results {*}[my MergeSlots $fd [/ $selFrom $step] $multiple]
        incr selCount -1
        incr selFrom $selStep
      }
      chan close $fd
    }
    return $results
  }
  
  method MergeSlots {fd slot nslots} {
    # Combine num/min/max/sum data from multiple slots
    Ju assert {$slot <= $currSlot}
    while {[incr nslots -1] >= 0} {
      if {$slot >= $currSlot - $count + 1} {
        chan seek $fd [* [% $slot $count] $width]
        binary scan [read $fd $width] $type num min max sum
        if {$num < 0} break
        if {$num > 0} {
          incr nums $num
          #FIXME a very ugly way to remove trailing ".0" for integer values
          # this happens when the storage format on file is float or double
          foreach v {min max sum} {
            if {[string match {*.0} [set $v]]} {
              set $v [string range [set $v] 0 end-2]
            }
          }
          lappend mins $min
          lappend maxs $max
          lappend sums $sum
        }
      }
      incr slot
    }
    if {![info exists nums]} {
      return {0 0 0 0}
    }
    list $nums [min {*}$mins] [max {*}$maxs] [+ {*}$sums]
  }
  
  method SendToChild {secs} {
    # Pass collected data down the bucket chain.
    # puts "AGGREGATE [clock format $secs -format %H:%M:%S] ${chstep}s"
    set chcount [/ $chstep $step]
    set chslot [* [/ $secs $chstep] $chcount]
    set fd [my Open r]
    $child aggregate $secs [my MergeSlots $fd $chslot $chcount] 1
    chan close $fd
  }
}
