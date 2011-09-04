Jm doc "Show recent temperatures as graph in the browser."
Webserver hasUrlHandlers

# This demo needs historical data, as generated by leaving the "history-test"
# example running for a while (preferably overnight for a detailed graph).

variable pattern reading:*:temp

# Flot wants *local* times, so we calculate how many seconds to add
# (this takes the current date as reference, not accurate after a DST change)
variable offsetTZ [- 43200 [% [clock scan 12:00] 86400]]

proc APP.READY {} {
  # Called once during application startup.
  variable pattern
  History group $pattern 2d/1m 1w/5m 3y/1h
}

proc /: {} {
  # Respond to "/" url requests.
  set html [Ju readFile [Ju mySourceDir]/page.tmpl]
  dict set response content [wibble template $html]
}

proc /data.json: {} {
  # Returns a JSON-formatted array with all current values.
  variable pattern
  # construct a map of all parameters we're interested in
  foreach x [lsearch -all -inline [Stored map state] $pattern] {
    set where [lindex [split $x :] 1]
    set map($where) $x ;# only keep one when there are multiple sources
  }
  # create an index, with the historical data we have so far
  foreach x [lsort -dict [array names map]] {
    set data [GetHistory $map($x) 1d 10m]
    set entry [list label [Ju toJson $x -str] data $data]
    lappend index [Ju toJson $entry -dict -flat]
  }
  dict set response header content-type {"" application/json charset utf-8}
  dict set response content [Ju toJson $index -list -flat]
}

proc GetHistory {param range step} {
  # Return historical data for one parameter, formatted as JSON for Flot
  variable offsetTZ
  set range [Ju asSeconds $range]
  set step [Ju asSeconds $step]
  set count [/ $range $step]
  set now [clock seconds]
  set from [- $now [% $now $step] $range]
  # convert history results into a pairwise JSON list for Flot
  set data {}
  foreach {num min max sum} [History query $param $from $step $count] {
    if {$num > 0} {
      set value [Driver scaledInt [/ $sum $num] 1] ;#FIXME hard-coded scale!
      lappend data [Ju toJson [list [* [+ $from $offsetTZ] 1000] $value] -list]
    }
    incr from $step
  }
  # the result is a list of [time,value] lists
  Ju toJson $data -list -flat
}