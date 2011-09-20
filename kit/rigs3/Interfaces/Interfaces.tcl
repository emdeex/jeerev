Jm doc "Utility code for the different hardware interfaces."

proc view {{cmd ""} args} {
  variable view
  if {$cmd eq ""} {
    return $view
  }
  View $cmd $view {*}$args
}

Ju cachedVar view . {
  variable view [CollectViewInfo]
}

proc CollectViewInfo {} {
  #TODO get rid of this proc when (if?) Ju cachedVar adds an "apply" layer
  View def name,path [SysDep listSerialPorts]
}
