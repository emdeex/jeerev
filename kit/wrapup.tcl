# Generate a wrapped starkit with the contents of the "kit" directory.

package require vfs::mk4

set dest jeemon-rev

set prefix [string map [list BS \\ EOF \32 NL \n] \
{#!/bin/sh
#BS
exec jeemon "$0" ${1+"$@"}
package require starkit
starkit::header mk4 -readonly
EOF################################NL}]

if {[string length $prefix] % 16 != 0} {
  error "bad starkit prefix ([string length $prefix]b)"
}

# save the starkit prefix
set fd [open $dest w]
chan configure $fd -translation binary
chan puts -nonewline $fd $prefix
chan close $fd

# copy the kit directory as Metakit starkit
set db [vfs::mk4::Mount $dest $dest]
file copy -force kit/. $dest
vfs::mk4::Unmount $db $dest

catch { file attributes $dest -permissions +x }
puts $dest:
puts "  [file size $dest] bytes"
