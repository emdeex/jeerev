Jm doc "This example replays messages which were recorded earlier."
Jm needs Replay

# report one line on the console for each decoded/submitted state change
State subscribe * {apply {x { puts "$x = [State get $x]" }}}
