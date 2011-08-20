Jm doc "Listen for 'collectd' info on the std UDP multicast port."

proc Dump {data} {
  puts [Config emit $data]
  puts #[string repeat - 40]
  # puts $data\n
}

collectd listen [namespace which Dump]
