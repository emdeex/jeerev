Jm doc "Utility code for active hardware devices."

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
  View def name,driver $::Drivers::registered
}
