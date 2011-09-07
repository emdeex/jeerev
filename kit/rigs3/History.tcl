Jm doc "Manage historical data storage."
Webserver hasUrlHandlers

variable collector  ;# key = param, value = list of values to aggregate

proc APP.READY {} {
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
  wibble pageResponse text [query {*}[split $args /]]
}

proc dump {fname} {
  # Dump contents of a binary history file - can be used from the command line.
  if {[regexp {.-(\w\w\w\w)$} $fname - type]} {
    set width [string length [binary format $type 0 0 0 0]]
    set fd [open $fname]
    chan configure $fd -translation binary
    for {set i 0} {![chan eof $fd]} {incr i} {
      set bytes [chan read $fd $width]
      binary scan $bytes c num
      if {$num < 0} {
        binary scan $bytes cI num slot
        puts "$i: SLOT $slot" ;# [binary encode hex $bytes]
      } else {
        binary scan $bytes $type num min max sum
        if {$num > 0} {
          # the formatting removes trailing ".0" suffixes, see also MergeSlots
          puts [format {%d: %d %.10g %.10g %.10g} $i $num $min $max $sum]
        }
      }
    }
    chan close $fd
  }
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
  variable logMap
  LogRollover $time
  if {![info exists fd]} {
    LogInit
  }
  if {![info exists logMap($param)]} {
    set logMap($param) [array size logMap]
    chan puts $fd [list $logMap($param) $param *] ;# save as new ID marker
  }
  # store time differences (or the full time, when starting up)
  chan puts $fd [list $logMap($param) $value [- $time $lastTime]]
  set lastTime $time
}

proc LogRollover {time} {
  # Switch to a new log file every once in a while.
  variable fd
  variable logSlot
  set logSize 3600
  if {![info exists logSlot]} {
    set logSlot [/ $time $logSize]
  }
  if {$time / $logSize > $logSlot} {
    set logSlot [/ $time $logSize]
    chan close $fd
    unset fd
    # puts "history log rollover [clock format [* $logSlot $logSize]]"
    file rename -force [Stored path history.log] [Stored path history.prev]
  }
}

proc LogInit {} {
  # Start logging, re-init parameter id map from file if it's present.
  variable fd
  variable lastTime
  variable logMap
  # reconstruct the parameter id map from what's on file so far
  array unset logMap
  foreach {i v t} [Ju readFile [Stored path history.log]] {
    if {$t eq "*"} {
      set logMap($v) $i
    }
  }
  # now we can start appending new entries to this file
  set fd [open [Stored path history.log] a]
  chan configure $fd -buffering none  
  set lastTime 0
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
  set values [dict get $myData values]
  set num [llength $values]
  if {$num > 0} {
    set chain [dict get $myData chain]
    if {$chain ne ""} {
      dict extract $myData slot minStep
      set tuple [list $num [min {*}$values] [max {*}$values] [+ {*}$values]]
      $chain aggregate [* $slot $minStep] $tuple
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
    set filler [binary format $type 0 0 0 0]
    set emptySlots [string repeat $filler $count]
    append emptySlots [binary format cI -1 0]
    chan puts -nonewline $fd $emptySlots
    chan close $fd
  }
  
  method SetType {low high} {
    # Determine the datatypes and sizes/widths to use for each slot.
    if {[string first . $low$high] >= 0} {
      set type Srrr
    } else {
      set type Sqqq
      foreach {b t} { 7 Sccs 15 Sssi 31 Siiw 63 Swwq } {
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
    
  method ToBinary {slot values} {
    # Convert a set of values to the binary format stored on file.
    Ju assert {$currSlot - $count < $slot && $slot <= $currSlot}
    Ju assert {[lindex $values 0] > 0}
    set fmt $type
    if {$slot == $currSlot} {
      append fmt cI
      lappend values -1 $slot
    }
    binary format $fmt {*}$values      
  }
  
  method aggregate {secs values} {
    # Aggregate and store new values into the proper slot.
    set slot [/ $secs $step]
    if {$slot > $currSlot + $count} {
      set currSlot [- $slot $count] ;# large gap, avoid clearing far too often
    }
    # Ju assert {$slot >= $currSlot}
    set fd [my Open]
    # don't leave gaps, fill empty slots between last one and new one
    while {$slot > $currSlot} {
      if {$slot == [incr currSlot]} break
      my Store $fd $currSlot $filler
    }
    my Store $fd $slot [my ToBinary $slot $values]
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
      set bytes [chan read $fd $width]
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
        binary scan [chan read $fd $width] $type num min max sum
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
          # alternative, not sure which is better
          # lappend mins [format %.10g $min]
          # lappend maxs [format %.10g $max]
          # lappend sums [format %.10g $sum]          
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
    set data [my MergeSlots $fd $chslot $chcount]
    if {[lindex $data 0] > 0} {
      $child aggregate $secs $data
    }
    chan close $fd
  }
}
