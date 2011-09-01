Jm doc "Manage historical data storage"

Ju cachedVar lastTime - {
  variable lastTime 0
}

proc APP.READY {} {
  variable fd [open [Stored path history.last] a+]
  chan configure $fd -buffering none
  
  State subscribe * [namespace which StateChanged]
}

proc StateChanged {param} {
  variable fd
  variable lastTime
  dict extract [State getInfo $param] v t
  set id [Stored map history $param]
  if {$id eq ""} {
    set id [dict size [Stored map history]]
    Stored map history $param $id
  }
  # store difference in time (or full time once, after we just started up)
  puts $fd [list $id $v [- $t $lastTime]]
  set lastTime $t
}
