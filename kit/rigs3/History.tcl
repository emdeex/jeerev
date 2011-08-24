Jm doc "Manage historical data storage"

proc APP.READY {} {
  RawStore create n-49h-30s
  RawStore create n-9w-5m
  RawStore create n-105w-60m
  # n-9w-5m submit abc 123
  # n-105w-60m submit abc 123
  State subscribe * [namespace which StateChanged]
}

# proc StateChanged {name} {
#   variable sizes
#   # puts <$args>
#   dict extract [State getInfo $name] v t
#   set path x-hist/[string map {: /} $name] ;#FIXME
#   if {![file exists $path.txt]} {
#     file mkdir [file dir $path]
#     variable defaults
#     Ju writeFile $path.txt $defaults -newline
#   }
#   dict extract [Ju readFile $path.txt] step range type
#   set step [Ju asSeconds $step]
#   set range [Ju asSeconds $range]
#   set count [/ $range $step]
#   set width [dict get $sizes $type]
#   if {![file exists $path]} {
#     variable nulls
#     set missing [binary format $type [dict get $nulls $type]]
#     Ju writeFile $path [string repeat $missing $count] -binary
#   }
# }

proc StateChanged {name} {
  variable sizes
  # puts <$args>
  dict extract [State getInfo $name] v t
  n-49h-30s submit $name $v $t
  n-9w-5m submit $name $v $t
  n-105w-60m submit $name $v $t
}

Ju classDef RawStore {
  variable type range step count path start null width map fd
  
  constructor {} {
    lassign [split [namespace tail [self]] -] type range step
    set range [Ju asSeconds $range]
    set step [Ju asSeconds $step]
    set count [/ $range $step]    

    set nulls {
      c -128 t -32768 n -2147483648 m -9223372036854775808 f NaN d NaN
    }
    set null [dict get $nulls $type]
    set width [string length [binary format $type $null]]

    set path [Config history:path x-hist]/[namespace tail [self]]
    if {![file exists $path.keys]} {
      file mkdir [file dir $path]
      set start [clock scan 0:00]
      set map {}
      my SaveMap
      Ju writeFile $path.values "" -binary
    }
    
    set map [lassign [Ju readFile $path.keys] header]
    dict extract $header start
    set fd [open $path.values r+]
    fconfigure $fd -translation binary -buffering none
  }
  
  destructor {
    close $fd
  }
  
  method SaveMap {} {
    set out [linsert $map 0 "{H 1 start $start}"]
    Ju writeFile $path.keys [join $out \n] -newline -atomic
  }
  
  method submit {key value {time ""}} {
    if {$time eq ""} {
      set time [clock seconds]
    }
    set id [lsearch $map $key]
    if {$id < 0} {
      set id [my ExtendFile $key]
    }
    set slot [% [/ [- $time $start] $step] $count]
    seek $fd [* [+ [* $id $count] $slot] $width]
    # puts "id $id slot $slot seek [* [+ [* $id $count] $slot] $width] : $key"
    if {![string is int -strict $value]} {
      set value $null
    }
    puts -nonewline $fd [binary format $type $value]
  }
  
  method ExtendFile {key} {
    set id [llength $map]
    lappend map $key
    my SaveMap
    seek $fd [* $id $width $count]
    puts -nonewline $fd [string repeat [binary format $type $null] $count]
    return $id
  }
}