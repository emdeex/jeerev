Jm doc "Listen for 'collectd' info on the std UDP multicast port."

# report one line on the console for each decoded/submitted state change
State subscribe * {apply {x { puts "$x = [State get $x]" }}}

collectd listen sysinfo
