Jm doc "Remote device interface."

# This "interface" does not use connections or sessions, it supports devices
# which automatically deal with submitted readings, based on their device name.

proc VIEW {} {
  View def name,path
}

proc listen {} {
  # not yet...
}
