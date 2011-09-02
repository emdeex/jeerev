Jm doc "Manage historical data storage."

variable collector  ;# key = param, value = list of values to aggregate

Ju cachedVar lastTime - {
  variable lastTime 0
}

proc APP.READY {} {
  variable fd [open [Stored path history.log] a+]
  chan configure $fd -buffering none
  
  DefineBucket 15s 10m
  DefineBucket 1m 1h
  DefineBucket 5m 12h
  # DefineBucket 1m 2d
  # DefineBucket 1h 3y

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

proc DefineBucket {step range} {
  set step [Ju asSeconds $step]
  set range [Ju asSeconds $range]
  
  variable buckets
  set buckets($step) $range
  
  puts " step $step range $range count [/ $range $step]"
  
  variable minStep
  if {$step < [Ju get minStep 9999]} {
    set minStep $step
  }
}

proc CollectValue {param value time} {
  # Collect and aggregate values according to the different buckets we have.
  upvar [namespace current]::collector($param) myData
  if {![info exists myData]} {
    SetupCollector $param 0 9999
  }
  variable minStep
  set slot [/ $time $minStep]
  if {$slot ne [dict get $myData slot]} {
    FlushSlot $param
    dict set myData slot $slot
  }
  dict lappend myData values $value
}

proc SetupCollector {param low high} {
  variable buckets
  upvar [namespace current]::collector($param) myData
  set myData {chain {} slot -1 values {}}
  # set up buckets in decreasing step size
  set prevStep ""
  set prevObj ""
  foreach step [lsort -dec -int [array name buckets]] {
    Ju assert {$prevStep eq "" ||
                $prevStep % $step == 0 && $prevStep / $step >= 3}
    set obj [Bucket new $param $step $buckets($step) $low $high $prevObj]
    set prevStep $step
    set prevObj $obj
  }
  dict set myData chain $obj
}

proc FlushSlot {param} {
  variable minStep
  upvar [namespace current]::collector($param) myData
  set slot [dict get $myData slot]
  set values [dict get $myData values]
  if {[llength $values] > 0} {
    [dict get $myData chain] aggregate [* $slot $minStep] $values
    #TODO propagate down (needs bucket select code)
  }
  dict set myData values {}
}

Ju classDef Bucket {
  variable param step range count child type filler width \
            prevSecs fname bfd currSlot
  
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
    set bfd [open $fname a+]
    chan configure $bfd -translation binary -buffering none
    if {[file size $fname] == 0} {
      set filler [binary format $type 0 0 0 0]
      set emptySlots [string repeat $filler $count]
      # don't go back in time more than the total range we're storing
      set firstSlot [/ [- [clock seconds] $range] $step]
      append emptySlots [binary format cI -1 $firstSlot]
      chan puts -nonewline $bfd $emptySlots
    }
    my RecoverSlot
  }
  
  destructor {
    chan close $bfd
  }
  
  method SetType {low high} {
    if {[string first . $low$high] >= 0} {
      set type crrr
    } else {
      set type cqqq
      foreach {b t} { 7 cccs 15 cssi 23 ciii 31 ciiw 63 cwwq } {
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
    puts " : $num $min $max $sum - $values"
    binary format ${type}cI $num $min $max $sum -1 $slot
  }
  
  method aggregate {secs values} {
    # Aggregate and store new values into the proper slot.
    set slot [/ $secs $step]
    Ju assert {$slot >= $currSlot}
    # don't leave gaps, fill empty slots between last one and new one
    while {$slot != $currSlot} {
      my Store [incr currSlot] $filler
    }
    my Store $slot [my ToBinary $slot $values]
  }
  
  method Store {slot bytes} {
    chan seek $bfd [* [% $slot $count] $width]
    chan puts -nonewline $bfd $bytes
    set secs [* $slot $step]
    if {$child ne "" && $prevSecs != 0 && ![$child sameSlot $secs $prevSecs]} {
      my SendToChild $prevSecs
    }
    set prevSecs $secs
  }
  
  method RecoverSlot {} {
    chan seek $bfd 0
    while true {
      set bytes [read $bfd $width]
      Ju assert {[string length $bytes] >= 5}
      binary scan $bytes cI tag slot
      if {$tag == -1} {
        puts "recovered: [clock format [* $slot $step]] ($fname)"
        set currSlot $slot
        return
      }
    }
  }
  
  method SendToChild {secs} {
    puts "AGGREGATE [clock format $secs -format %H:%M:%S]"
  }
}
