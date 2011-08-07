Jm doc "Rig wrapper around the Metakit database package."

package require Mk4tcl

# NOTE: be very careful with code in here, use "::set" i.s.o. "set", etc!

proc layout {view def} {
  # Convenience proc to allow defining MK view structures in a nicer way.
  regsub -all -line {#.*} $def "" def
  regsub -all {(\w+)\s+(\{)} $def {\2\1 \2} def
  regsub -all {(\})} $def {\1\1} def
  view layout $view $def
}
