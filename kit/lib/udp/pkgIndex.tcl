package require platform

switch [platform::generic] {
  windows-ix86 {
    package ifneeded udp 1.0.9 [list load [file join $dir udp109.dll]]
  }
  macosx-ix86 - macosx-ppc {
    package ifneeded udp 1.0.9 [list load [file join $dir libudp1.0.9.dylib]]
  }
  linux-ix86 {
    package ifneeded udp 1.0.9 [list load [file join $dir libudp1.0.9.so]]
  }
  linux-x86_64 {
    package ifneeded udp 1.0.9 [list load [file join $dir libudp1.0.9-x64.so]]
  }
}
