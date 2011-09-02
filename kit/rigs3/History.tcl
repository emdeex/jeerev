Jm doc "Manage historical data storage."

variable collector  ;# key = param, value = list of values to aggregate

Ju cachedVar lastTime - {
  variable lastTime 0
}

proc APP.READY {} {
  variable fd [open [Stored path history.log] a+]
  chan configure $fd -buffering none
  
  DefineBuckets test:* 10m/15s 1h/1m 12h/5m
  DefineBuckets reading:* 2d/1m 1w/5m 3y/1h
  DefineBuckets sysinfo:* 1w/5m

  State subscribe * [namespace which StateChanged]
}

proc StateChanged {param} {
  dict extract [State getInfo $param] v t
  # only keep track of numeric data
  if {[string is double -strict $v]} {
    LogValue $param $v $t
    CollectValue $param $v $t
  }
}

proc LogValue {param value time} {
  # Save a new parameter value to the history log file
  variable fd
  variable lastTime
  set id [Stored mapId history $param]
  # store time differences (or the full time, when starting up)
  puts $fd [list $id $value [- $time $lastTime]]
  set lastTime $time
}

proc DefineBuckets {pattern args} {
  variable buckets
  puts "  $pattern"
  foreach x $args {
    lassign [split $x /] range step
    set step [Ju asSeconds $step]
    set range [Ju asSeconds $range]
    dict lappend buckets($pattern) $step $range
    puts "    step $step range $range count [/ $range $step]"
  }
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
        set obj [Bucket new $param $s $r $low $high $prevObj]
        set prevStep $s
        set prevObj $obj
      }
      dict set myData chain $obj
      return
    }
  }
}

proc FlushSlot {param} {
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
  variable param step range count child type filler width \
            prevSecs fname currSlot
  
  constructor {bparam bstep brange blow bhigh bchild} {
    set param $bparam
    set id [Stored mapId hist-bin $param]
    set step $bstep
    set range $brange
    set count [/ $brange $bstep]
    set child $bchild
    my SetType $blow $bhigh
    set prevSecs 0
    file mkdir [Stored path hist-bin]
    set fname [Stored path hist-bin/$id-$step-$count-$type]
    if {![file exists $fname]} {
      my CreateFile
    }
    my RecoverSlot
  }
  
  method CreateFile {} {
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
    expr {$t1 / $step == $t2 / $step}
  }
    
  method ToBinary {slot values} {
    set num [llength $values]
    set min [min {*}$values]
    set max [max {*}$values]
    set sum [+ {*}$values]
    puts " : $num $min $max $sum ($param)"
    binary format ${type}cI $num $min $max $sum -1 $slot
  }
  
  method aggregate {secs values} {
    # Aggregate and store new values into the proper slot.
    set slot [/ $secs $step]
    Ju assert {$slot >= $currSlot}
    set fd [my Open]
    # don't leave gaps, fill empty slots between last one and new one
    while {$slot != $currSlot} {
      my Store $fd [incr currSlot] $filler
    }
    my Store $fd $slot [my ToBinary $slot $values]
    chan close $fd
  }
  
  method Open {{mode r+}} {
    set fd [open $fname $mode]
    chan configure $fd -translation binary -buffering none
    return $fd
  }
  
  method Store {fd slot bytes} {
    chan seek $fd [* [% $slot $count] $width]
    chan puts -nonewline $fd $bytes
    set secs [* $slot $step]
    if {$child ne "" && $prevSecs != 0 && ![$child sameSlot $secs $prevSecs]} {
      my SendToChild $prevSecs
    }
    set prevSecs $secs
  }
  
  method RecoverSlot {} {
    set fd [my Open r]
    chan seek $fd 0
    while true {
      set bytes [read $fd $width]
      Ju assert {[string length $bytes] >= 5}
      binary scan $bytes cI tag slot
      if {$tag == -1} {
        puts "recovered: [clock format [* $slot $step]] ($fname)"
        set currSlot $slot
        break
      }
    }
    chan close $fd
  }
  
  method SendToChild {secs} {
    puts "AGGREGATE [clock format $secs -format %H:%M:%S]"
  }
}
