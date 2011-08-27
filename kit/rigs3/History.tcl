Jm doc "Manage historical data storage"

# This code implements a very crude storage format with 14 bytes per value:
#   16b ID (short int) + 64b value (double) + 32b timestamp (long int)
# IDs are managed as a file with a list of keys and using the position as ID.
#
# Only strictly numeric values are stored, not IP addresses and other strings.
# This could easily be improved and optimized, but for now it's good enough.
#
# The second (larger) part of this code stores aggregated data in a Metakit
# datafile. It's a bit slow for practical use, because large chunks ar flushed
# a bit too frequently. One solution is to do far more in-mem, and flush less.
# All procs involved in this mechanism have names ending in "HistDB".

proc APP.READY {} {
  variable path [Storage path hist]
  variable keys [Ju readFile $path.keys]
  
  variable fd [open $path a+]
  fconfigure $fd -translation binary -buffering none
  
  OpenHistDB $path.db

  State subscribe * [namespace which StateChanged]
}

proc StateChanged {name} {
  dict extract [State getInfo $name] v t
  # that funny-looking "$v == $v" condition rules out things like "NaN"
  if {[string is double -strict $v] && $v == $v} {
    AddOne $name $v $t
    AddToHistDB $name $v $t
  }
}

proc AddOne {name value time} {
  variable path
  variable keys
  variable fd
  set id [lsearch $keys $name]
  if {$id < 0} {
    set id [llength $keys]
    lappend keys $name
    Ju writeFile $path.keys [join $keys \n] -newline -atomic
    
    #FIXME added for testing only
    query $name 60 15
  }
  puts -nonewline $fd [binary format tdn $id $value $time]
}

proc OpenHistDB {dbpath} {  
  mk file open hdb ;# $dbpath
  mk layout hdb.histories {
    key       # list with 3 items: param type step
    start:I   # start time
    slots     # complete slots, as list
    accum     # accumulator for last values, as list
  }
  
  variable buckets {}
  mk loop c hdb.histories {
    set b [mk get $c key]
    dict lappend buckets [lindex $b 0] $b
  }
}

proc LookupHistDB {key} {
  set r [mk select hdb.histories key $key]
  if {[llength $r] == 1} {
    return hdb.histories!$r
  } else {
    error "$key: not found in hdb.histories"
  }
}

proc AddToHistDB {name value time} {
  # Go through all known buckets for this parameter, and aggregate as needed.
  variable buckets
  set value [format %.10g $value] ;# keep float accuracy reasonably short
  set bucketList [dict get? $buckets $name]
  Ju map [namespace which AccumulateHistDB] $time $value $bucketList
  return
}

proc AccumulateHistDB {time val bucket} {
  # Resembles round-robin logic, but shifting out old and appending new data.
  # time: advance to this time, in seconds
  # val: accumulate this value
  # bucket: which bucket to operate on
  lassign $bucket param type step
  # collect all info into variables
  set row [mk get [LookupHistDB $bucket]]
  dict with row {}
  set limit [llength $slots]
  # all info is now available as variables
  set pos [expr {$time/$step-$start}]
  if {$pos != $limit} {
    if {$pos < $limit} {
      error "can't go back in time ($pos $start)"
    }
    if {$pos >= 2 * $limit} {
      # advancing by an amount exceeding the total buffer, so clear all slots
      set pos $limit
      set start [expr {$time/$step-$pos}]
      set slots [lrepeat $limit ""]
      set accum {}
    }
    # flush the currently accumulated values into the next slot and then
    # roll the buffer (and empty accum) forward until our time is reached
    while {$pos > $limit} {
      set slots [lrange $slots 1 end]
      lappend slots [AggregateHistDB $accum $type]
      set accum {}
      incr start
      incr pos -1
    }
    mk set [LookupHistDB $bucket] start $start slots $slots accum {}
  }

  mk set [LookupHistDB $bucket] accum [lappend accum $val]
}

proc query {param step count {type avg} {time ""}} {
  # Ask for historical values. Side effect is to start tracking them.
  # param: parameter name
  # step: step size, in seconds
  # count: number of values to return
  # type: typeof aggregation performed on each value
  # time: reference starting time, defaults to now
  # Returns the requested data items as list (missing values as empty strings).
  set bucket [list $param $type $step]
  if {[llength [mk select hdb.histories key $bucket]] == 0} {
    variable buckets
    dict lappend buckets $param $bucket
    # create a new bucket for this request, starting out with no data
    mk set hdb.histories![mk view size hdb.histories] \
        key $bucket start 0 slots {} accum {} ;#FIXME ugly code
  }
  if {$time eq ""} {
    set time [clock seconds]
  }
  GetDataHistDB $bucket $time $count
}

proc GetDataHistDB {bucket time count} {
  # time: reference starting time
  # count: number of values to return
  lassign $bucket param type step
  set row [mk get [LookupHistDB $bucket]]
  dict with row {}
  set limit [llength $slots]
  # extend the number of entries in this bucket if needed
  if {$count > $limit + 1} {
    set more [expr {$count-$limit-1}]
    set slots [linsert $slots 0 {*}[lrepeat $more ""]]
    incr start -$more
    mk set [LookupHistDB $bucket] start $start slots $slots
    set limit [expr {$count - 1}]
  }
  # extract the requested data range, padding on both sides with "" if needed
  set last [expr {$time/$step-$start-1}]
  set first [expr {$last-$count+1}]
  if {$first < 0} {
    set results [lrepeat [expr {-$first}] ""]
    set first 0
  }
  lappend results {*}[lrange $slots $first $last]
  # limit entry is not part of slots but the result of calling AggregateHistDB
  if {$last >= $limit} {
    lappend results [AggregateHistDB $accum $type]
  }
  # pad with empty values if there were not enough slots with data
  concat $results [lrepeat [expr {$count - [llength $results]}] ""]
}

proc AggregateHistDB {values type} {
  # Calculate an aggregate result from a list of values.
  # values: list of input values
  # type: type of aggregation to perform
  # Returns the aggregated value, or an empty string if none can be calculated.
  set n [llength $values]
  switch $type {
    count   { return $n }
    first   { return [lindex $values 0] }
    last    { return [lindex $values end] }
    avg     { if {$n > 0} { return [expr "([join $values +])/$n"] } }
    min     { if {$n > 0} { return [tcl::mathfunc::min {*}$values] } }
    max     { if {$n > 0} { return [tcl::mathfunc::max {*}$values] } }
    sum     { if {$n > 0} { return [expr "[join $values +]"]} }
    default { error "$type: bad aggegration type" }
  }
}
