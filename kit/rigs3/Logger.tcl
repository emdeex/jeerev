Jm doc "Support for logging information to text files with periodic rotation."

# default settings, these can be changed in the config file:
#
#   logger: {
#     logdir ./logger
#     gmt 1
#   }

Ju cachedVar loginfo . {
  #FIXME why not "-once"?
  #TODO extend cachedVar to create vars if not already done so in the script
  variable loginfo ""
} -cleanup {
  variable loginfo
  catch { close [dict get $loginfo fd] }
}

proc DRIVER.DISPATCH {device message} {
  variable loginfo
  set dir [Config logger:logdir ./logger]
  set gmt [Config logger:gmt 1]
  # figure out the name of the log file to use
  dict extract $loginfo fd current
  set now [clock millis]
  set when [/ $now 1000]
  set fname $dir/[clock format $when -gmt $gmt -format "%Y%m%d"].txt
  if {$fname ne $current} {
    catch { close $fd }
    file mkdir $dir
    set existing [file exists $fname]
    set fd [open $fname a]
    chan configure $fd -buffering line
    if {!$existing} {
      Log logdata {created $fname}
    }
    file delete $dir.txt
    file link $dir.txt $fname
    Log logger {logging to $fname}
    set current $fname
    dict inject loginfo fd current
  }
  # construct a log entry which can be executed as Tcl command later
  if {![string is list -strict $message]} {
    set message [list $message]
  }
  puts $fd [list L [Log timestamp $now $gmt] $device {*}$message]
}
