Jm doc "Driver for the HMNODE2 power metering sketch."

proc decode {event message} {
  # Called on each incoming message.
  if {[string match "HM3 *" $message]} {
    set msg [lassign $message cmd id]
    set node [& $id 0x1F]
    set raw [binary format c* $msg]
    # typedef struct {
    #     uint16_t count :12; // counter, wraps after reaching 4095
    #     uint16_t value :2;  // current sensor value (only 0 or 1 used)
    #     uint16_t wrap  :1;  // set if the counter has wrapped at least once
    #     uint16_t fresh :1;  // set if this count is a new value
    #     uint16_t rate;      // number of milliseconds since last change
    # } TxItem;
    # struct {
    #     uint16_t seqnum :6; // increased by one for each new packet
    #     uint16_t origin :2; // can deal with up to 4 units
    #     TxItem data[NSIGS]; // sensor data, 32 bits for each sensor
    # } payload;
    Driver bitSlicer $raw \
      seq 6 orig 2 c1 12 v1 2 w1 1 f1 1 r1 16 c2 12 v2 2 w2 1 f2 1 r2 16
    # rates are stored as a sort of pseudo floats, convert them back first
    set r1 [UnpackValue $r1]
    set r2 [UnpackValue $r2]
    #TODO the electricity and gas pulse rates are still hard coded (375 & 100)
    set x1 375
    set x2 100
    # set cwrap 4096
    # each incoming packet produces four different readings
    if {$f1} {
      set pu [/ [* 3600 1000000] [* $r1 $x1]]
      set pc [/ [* 10000 $c1] $x1]
      $event submit erate $pu ;# -desc "power use" -unit W
      $event submit etotal $pc ;# -desc "power, cumulative" -unit Wh -scale 1
    }
    if {$f2} {
      set gr [/ [* 3600 1000000] [* $r2 $x2]]
      set gc [/ [* 100 $c2] $x2]
      $event submit grate $gr ;# -desc "gas rate" -unit l/h
      $event submit gtotal $gc ;# -desc "gas, cumulative" -unit m3 -scale 2
    }
    # 3rd set of values ignored: always zero
  }
}

proc UnpackValue {r} {
  # Convert the 3-bit exp + 13-bit mantissa ms time back to a long int.
  expr {($r & 0x1FFF) << (2 * ($r >> 13))}
}
