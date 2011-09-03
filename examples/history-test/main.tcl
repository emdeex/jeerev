Jm doc "Collect some data to test the round-robin storage logic."

# This code may allocate dozens of MB's of disk storage, depending on the setup.
# There is no user interface, it just starts collecting data. Created as first
# step to evaluate usability and performance of round-robin storage - by leaving
# it running for a while, I end up with lots of test data in stored/hist-data/.
# Each of the sections below can be enabled or disabled independently.

# define a group for frequent test events and start collecting them
if {1} {
  History group test:* 10m/15s 1h/1m 12h/5m
  proc Periodic {} {
    after 3000 [namespace which Periodic]
    State put test:data [round [* [rand] 100]]
  }
  Periodic ;# start generating periodic test events
}

# define a group for collectd events and start collecting them
if {1} {
  History group sysinfo:* 1w/5m
  collectd listen sysinfo ;# only useful if some machines are running collectd
}

# define a group for replay events and start collecting them
if {1} {
  History group reading:* 2d/1m 1w/5m 3y/1h
  Jm needs Replay
}

# report one line on the console for each decoded/submitted state change
# State subscribe * {apply {x { puts "$x = [State get $x]" }}}
