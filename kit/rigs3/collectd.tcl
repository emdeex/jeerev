Jm doc "Support for collect packets, coming in over UDP."

package require udp

#TODO these tuple expansions should not be hard-coded
variable tuples {
  df:* {used free}
  disk:* {read write}
  interface:* {rx tx}
  load {short mid long}
  serial:* {rx tx}
  *:mysql_octets {rx tx}
  *:mysql_qcache {hits inserts not_cached prunes size}
  *:mysql_threads {running connected cached total-created}
}

variable types
variable level
if {![info exists types]} {
  # prepare some simple lookup tables
  if {![info exists types]} {
    set i -1
    foreach {typ fmt} {
      0 Str  1 Num  2 Str  3 Str  4 Str  5 Str  6 Val  256 Str  257 Num
    } {
      set types($typ) $fmt
      set level($typ) [incr i]
    }
    variable path {}
  }
}

proc listen {handler {group 239.192.74.66} {port 25826}} {
  set s [udp_open $port]
  fconfigure $s -buffering none -blocking 0 -mcastadd $group -translation binary
  fileevent $s readable [list [namespace which ReadUDP] $s $handler]
  return $s
}

proc ReadUDP {sock handler} {
  # Called whenever a UDP comes in.
  variable types
  variable level
  variable tuples
  variable path

  set data [read $sock]
  if {$data eq ""} return  
  set peer [fconfigure $sock -peer]

  set out {host ? time ?}
  set off 0
  while {$off + 4 < [string length $data]} {
    binary scan $data @${off}SS t l
    if {[info exists level($t)]} {
      set lvl $level($t)
      set val [$types($t) [string range $data [+ $off 4] [+ $off $l -1]]]
      # puts "[string repeat { } $lvl] $types($t) $val"
      while {$lvl >= [llength $path]} {
        lappend path _
      }
      if {$lvl == 4} {
        lset path 4 $val
      } else {
        set path [lreplace $path $lvl end $val]
      }
      if {$lvl == 6} {
        # keep same data structure while host and time stay the same
        lassign $path host time module
        set h [dict get $out host]
        if {$host ne $h || $time ne [dict get $out time]} {
          if {$h ne "?"} {
            $handler $out
          }
          set out [dict create host $host time $time]
        }
        dict set out addr [lindex $peer 0]
        # turn each collected value into a simple nested dictionary structure
        set keys [lrange $path 2 end-1]
        if {[lindex $keys 0] eq [lindex $keys 2]} {
          set keys [lreplace $keys 2 2]
        }
        set keys [lsearch -all -inline -not $keys _]
        if {[llength $val] > 1} {
          set k2 [string map {" " :} $keys]
          dict for {t t2} $tuples {
            if {[llength $val] == [llength $t2] && [string match $t $k2]} {
              append keys :
              set v2 {}
              foreach k $t2 v $val {
                lappend v2 $k $v
              }
              set val $v2
            }
          }
        }
        dict set out {*}[string map {" " ": "} $keys] $val
      } elseif {$lvl > 6} {
        #TODO handle notifications and severity levels
        Log coll? {$lvl: $peer $path}
      }
    }
    incr off $l    
  }
  {*}$handler $out
}

proc Str {b} {
  set b [string trim $b \0]
  if {$b eq ""} { set b _ }
  return $b
}

proc Num {b} {
  binary scan $b W v
  return $v
}

proc Val {b} {
  # puts [binary encode hex $b]
  binary scan $b S n
  binary scan $b @2c$n t
  set off [+ 2 $n]
  set out {}
  foreach x $t {
    set v ?
    if {$x == 1} {
      binary scan $b @${off}q v
      regsub {\.0$} $v {} v
    } else {
      binary scan $b @${off}W v
      if {$x != 2 && $v < 0} {
        set v [& $v 0xFFFFFFFFFFFFFFFF]
      }
    }
    lappend out $v
    incr off 8
  }
  return $out
}
