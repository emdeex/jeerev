Jm doc "RFM12B Command Calculator page handler."

variable title "RFM12B Command Calculator"
variable menu "RFM12B"

variable css {
  fieldset { padding: 0 6px 2px 8px; margin-bottom: 10px; }
  legend { width: 80%; }
  .block { float: left; margin-right: 16px; }
  .regcode { font-family: Courier; color: darkred; }
  .endcode { font-family: Courier; font-size: 85%; }
}

variable js {
  var o = ko.observable;
  var v = {
    CS: o(), bd: o(2), xc: o(8), tr: o(1), rf: o(1),
    PM: o(), er: o(1), eb: o(1), ex: o(0), es: o(1),
             eo: o(1), el: o(1), ew: o(0), ec: o(1),
    FS: o(), fc: o(1600),
    DR: o(), ps: o(0), rr: o(6),
    RC: o(), lg: o(0), rb: o(6), np: o(2), vd: o(1), dr: o(3),
    DF: o(), ft: o(1), qt: o(1), dm: o(2), ds: o(1),
    FR: o(), fl: o(9), fs: o(1), fe: o(1), so: o(2), rs: o(2),
    SP: o(), ss: o("D4"),
    AF: o(), am: o(3), or: o(1), af: o(1), sb: o(0), ha: o(0), fo: o(1),
    TC: o(), sh: o(1), dv: o(6), po: o(1),
    PS: o(), cr: o(3), pb: o(2), dd: o(1), ep: o(0),
    WT: o(), wr: o(0), wm: o(0),
    DC: o(), dc: o(0), ce: o(0),
    LB: o(), lb: o(10), pf: o(3),
  };
  
  v.CS = ko.dependentObservable(function() {
    var d = 0x8000;
    d += this.tr() ? 1 << 7 : 0; // el
    d += this.rf() ? 1 << 6 : 0; // ef
    d += this.bd() << 4; // b1 b0
    d += this.xc() - 1; // x3 x2 x1 x0
    return d.toString(16).toUpperCase();
  }, v);
  v.PM = ko.dependentObservable(function() {
    var d = 0x8200;
    d += this.er() ? 1 << 7 : 0; // er
    d += this.eb() ? 1 << 6 : 0; // ebb
    d += this.ex() ? 1 << 5 : 0; // et
    d += this.es() ? 1 << 4 : 0; // es
    d += this.eo() ? 1 << 3 : 0; // ex
    d += this.el() ? 1 << 2 : 0; // eb
    d += this.ew() ? 1 << 1 : 0; // ew
    d += this.ec() ? 1 << 0 : 0; // dc
    return d.toString(16).toUpperCase();
  }, v);
  v.FS = ko.dependentObservable(function() {
    var d = 0xA000;
    d += parseInt(this.fc()); // f11 .. f0
    return d.toString(16).toUpperCase();
  }, v);
  v.DR = ko.dependentObservable(function() {
    var d = 0xC600;
    d += this.ps() ? 1 << 7 : 0; // cs
    d += this.rr() << 0; // r6 .. r0
    return d.toString(16).toUpperCase();
  }, v);
  v.RC = ko.dependentObservable(function() {
    var d = 0x9000;
    d += (this.np() - 1) << 10; // p16
    d += (this.vd() - 1) << 8; // d1 d0
    d += (this.rb() - 1) << 5; // i2 i1 i0
    d += (this.lg() - 1) << 3; // g1 g0
    d += (this.dr() - 1) << 0; // r2 r1 r0
    return d.toString(16).toUpperCase();
  }, v);
  v.DF = ko.dependentObservable(function() {
    var d = 0xC228;
    d += (this.dm() - 1) << 7; // al
    d += (this.ds() - 1) << 6; // ml
    d += (this.ft() - 1) << 4; // s
    d += (parseInt(this.qt()) + 3) << 0; // f2 f1 f0
    return d.toString(16).toUpperCase();
  }, v);
  v.FR = ko.dependentObservable(function() {
    var d = 0xCA00;
    d += (this.fl() - 1) << 4; // f3 .. f0
    d += (2 - this.so()) << 3; // sp
    d += (this.fs() - 1) << 2; // al
    d += this.fe() ? 1 << 1 : 0; // ff
    d += (this.rs() - 1) << 0; // dr
    return d.toString(16).toUpperCase();
  }, v);
  v.SP = ko.dependentObservable(function() {
    var d = 0xCE00;
    d += parseInt(this.ss(), 16) << 0; // b7 .. b0
    return d.toString(16).toUpperCase();
  }, v);
  v.AF = ko.dependentObservable(function() {
    var d = 0xC400;
    d += (this.am() - 1) << 6; // a1 a0
    d += (this.or() - 1) << 4; // rl1 rl0
    d += this.sb() ? 1 << 3 : 0; // st
    d += this.ha() ? 1 << 2 : 0; // fi
    d += this.fo() ? 1 << 1 : 0; // oe
    d += this.af() ? 1 << 0 : 0; // en
    return d.toString(16).toUpperCase();
  }, v);
  v.TC = ko.dependentObservable(function() {
    var d = 0x9800;
    d += (this.sh() - 1) << 8; // mp
    d += (this.dv() - 1) << 4; // m3 .. m0
    d += (this.po() - 1) << 0; // p2 .. p0
    return d.toString(16).toUpperCase();
  }, v);
  v.PS = ko.dependentObservable(function() {
    var d = 0xCC02;
    d += (this.cr() - 1) << 5; // ob1 ob0
    d += (this.pb() - 1) << 4; // lpx
    d += this.ep() ? 1 << 3 : 0; // ddy
    d += this.dd() ? 1 << 2 : 0; // ddit
    d += (this.pb() - 1) << 0; // bw0
    return d.toString(16).toUpperCase();
  }, v);
  v.WT = ko.dependentObservable(function() {
    var d = 0xE000;
    d += this.wr() << 8; // r4 .. r0
    d += this.wm() << 0; // m7 .. m0
    return d.toString(16).toUpperCase();
  }, v);
  v.DC = ko.dependentObservable(function() {
    var d = 0xC800;
    d += this.dc() << 1; // d6 .. d0
    d += this.ce() ? 1 << 0 : 0; // en
    return d.toString(16).toUpperCase();
  }, v);
  v.LB = ko.dependentObservable(function() {
    var d = 0xC000;
    d += (this.pf() - 1) << 5; // d2 d1 d0
    d += (this.lb() - 1) << 0; // v3 .. v0
    return d.toString(16).toUpperCase();
  }, v);
  
  v.cs1 = ko.dependentObservable(function() {
    var b = this.bd();
    return [433, 868, 915][b-1];
  }, v);
  v.cs2 = ko.dependentObservable(function() {
    var b = this.bd();
    return [430, 860, 900][b-1];
  }, v);
  v.cs3 = ko.dependentObservable(function() {
    var b = this.bd();
    var d = [0.0025, 0.0050, 0.0075][b-1];
    return d.toFixed(4);
  }, v);
  v.cs4 = ko.dependentObservable(function() {
    var b = this.bd();
    var c1 = [1, 2, 3][b-1];
    var c2 = [43, 43, 30][b-1];
    var d = 10 * c1 * (c2 + this.fc() * 0.00025);
    return d.toFixed(4);
  }, v);
  v.dr1 = ko.dependentObservable(function() {
    var d = 10000.0 / 29 / (parseInt(this.rr()) + 1) / (1 + this.ps() * 7);
    return d.toFixed(3);
  }, v);
  v.sp1 = ko.dependentObservable(function() {
    var d = 0x12D00 + parseInt(this.ss(), 16);
    return d.toString(2).substring(this.so() == 1 ? 9 : 1);
  }, v);
  v.wt1 = ko.dependentObservable(function() {
    return this.wm() * (2 << this.wr());
  }, v);
  v.dc1 = ko.dependentObservable(function() {
    var d = (this.dc() * 2 + 1) / this.wm();
    return d.toFixed(2);
  }, v);
  
  ko.applyBindings(v);
}

variable fs1 {
  CS "Configuration Settings" {
    .block
      ['radio bd Band 433 868 915]
      : MHz
      br
      ['select xc "Xtal cap" 8.5 9.0 9.5 10.0 10.5 11.0 11.5 12.0 \
                             12.5 13.0 13.5 14.0 14.5 15.0 15.5 16.0]
      : pF
    .block
      ['checkbox tr "TX Register" rf "RX FIFO Buffer"]
  }
  PM "Power Management" {
    .block
      ['checkbox er "Enable Receiver" \
                 eb "Enable Base Band Block" \
                 ex "Enable Transmitter" \
                 es "Enable Synthesizer"]
    .block
      ['checkbox eo "Enable Crystal Osc" \
                 el "Enable Low-bat Detector" \
                 ew "Enable Wake-Up Timer" \
                 ec "Enable Clock Output Pin"]
  }
  FS "Frequency Setting" {
    .block
      : For 
      span/data-bind=text:cs1: ?
      : MHz: Fc = 
      span/data-bind=text:cs2: ?
      : + F x 
      span/data-bind=text:cs3: ?
      : MHz
      br
      ['text fc "F ="]
      : : Center Frequency = 
      span/data-bind=text:cs4: ?
      : MHz
  }
  DR "Data Rate" {
    .block
      ['checkbox ps "Enable Prescale (1/8)"]
      br
      ['text rr "Enter a value for R"]
      : : Data Rate = 
      span/data-bind=text:dr1: ?
      : kbps
  }
  RC "Receiver Control" {
    .block
      ['select lg "LNA Gain" Max -6 -14 -20]
      : dBm
      br
      ['select rb "RX Bandwidth" - 400 340 270 200 134 67]
      : kHz
    .block
      ['select np "Pin" nINT VDI]
      br
      ['select vd "VDI" Fast Medium Slow On]
    .block
      ['select dr "DRSSI" -103 -97 -91 -85 -79 -73]
      : dBm
  }
  DF "Data Filter & Clock Recovery" {
    .block
      ['select ft "Filter Type" Digital Analog]
      br
      ['select qt "Quality Threshold" 4 5 6 7]
    .block
      ['select dm "Recovery Mode" Manual Auto]
      br
      ['select ds "Recovery Speed" Slow Fast]
  }
  FR "FIFO and Reset Mode" {
    .block
      ['select fl "FIFO INT Level" 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15]
      br
      ['select fs "FIFO Fill Start" Sync Always]
      br
      ['checkbox fe "FIFO Fill Enabled"]
    .block
      ['select so "Sync on" 1 2]
      : bytes
      br
      ['select rs "Reset Sensitivity" High Low]
  }
}

variable fs2 {
  SP "Synchronization Pattern" {
    .block
      ['text ss "Synchronization Byte (HEX)"]
      : : 
      span/data-bind=text:sp1: ?
  }
  AF "Automatic Frequency Control" {
    .block
      ['select am "AFC Mode" "Auto mode off" \
                             "Runs only once after each power-up" \
                             "Keep the F-offset only during VDI=high" \
                             "Keep the F-offset value"]
      br
      ['select or "Offset Register Limit" "No retrictions" \
                                          "+15 .. -16" \
                                          "+7 .. -8" \
                                          "+3 .. -4"]
    .block
      ['checkbox af "Enable AFC"]
      br
      ['checkbox sb "Strobe"]
    .block
      ['checkbox ha "Enable High Accuracy (slower)"]
      br
      ['checkbox fo "Enable Frequency Offset Register"]
  }
  TC "TX Control" {
    .block
      ['select sh "Frequency Shift" Pos Neg]
      br
      ['select dv "Deviation" 15 30 45 60 75 90 105 120 \
                              135 150 165 180 195 210 225 240]
      : kHz
    .block
      ['select po "Power Out" 0 -3 -6 -9 -12 -18 -21]
      : dB
  }
  PS "PLL Settings" {
    .block
      ['select cr "Clock rise" Fast Medium Slow]
      br
      ['select pb "PLL Band" 86 256]
      : kbps
    .block
      ['checkbox dd "Disable Dither in PLL"]
      br
      ['checkbox ep "Enable Phase Detector Delay"]
  }
  WT "Wake-Up Timer" {
    .block
      : T = M x 2<sup>R</sup> :
      ['text wr "R ="]
      ['text wm "M ="]
      : : T =
      span/data-bind=text:wt1: ?
      : ms
  }
  DC "Low Duty-Cycle" {
    .block
      : DC = (D x 2 + 1) / M x 100%
      br
      ['text dc "D ="]
      : : Duty Cycle =
      span/data-bind=text:dc1: ?
      : \%
    .block
      ['checkbox ce "Enable"]
  }
  LB "Low Battery Detect and µC Clock" {
    .block
      ['select lb "Low-Battery Threshold" 2.2 2.3 2.4 2.5 2.6 2.7 2.8 2.9 \
                                          3.0 3.1 3.2 3.3 3.4 3.5 3.6 3.7]
      : V
    .block
      ['select pf "Clock Pin Frequency" 1.0 1.25 1.66 2.0 2.5 3.33 5.0 10.0]
      : MHz
  }
  "" "Other Commands" {
    .block
      : <b>B000 : RX Read</b> - read 8 bits from the receiver FIFO
      br
      : <b>B8xx : TX Write</b> - write 8 bits to the transmitter register
  }
}

variable credits {
  : With a tip-o-the-hat to the 
  a/href=http://www.w3.org/: W3C
  : consortium and the
  a/href=http://jquery.com/: jQuery
  : +
  a/href=http://knockoutjs.com/: Knockout
  : +
  a/href=http://www.tcl.tk/: Tcl
  : developers for setting great standards and sharing great tools.
}

variable tmpl [Sif html {
  [JScript wrap ['V js]]
  [JScript style ['V css]]
  .grid_7/style=margin-left:0
    % foreach {a k v} ['V fs1]
      [myFieldSet $a $k $v]
  .grid_7/style=margin-right:0
    % foreach {a k v} ['V fs2]
      [myFieldSet $a $k $v]
  .grid_14/style=margin-left:0
    br
    b
      : Corresponding C code for the RF12 driver in
      a/href=https://github.com/jcw/jeelib: JeeLib
    .endcode
      % foreach x {CS PM FS DR RC DF FR SP AF TC PS WT DC LB}
        : rf12_config(0x<span data-bind="text: $x">?</span>);
    br
    b
      : Other RFM12B calculators found on the web
    ul
      li
        a/href=http://www.kewlit.com/RFM12B/
          : Hope RFM12B / RFM12 Command Calculator
        : - Win32 app, written in Lazarus/Delphi, by Steve (tankslappa)
      li
        : Original 2009 Windows app in VB6 by TechnoFun
        : - link broken, see this
        a/href=http://rfm12-calculator.software.informer.com/: summary
      li
        : Partial app (half a GUI) for Mac OSX in Objective-C / Xcode, on
        % set url http://code.google.com/p/rfm12b-calculator
        a/href=$url/source/browse/#svn%2Fbranches%2FVer1-0: Google Code
}]

proc myFieldSet {var label def} {
  set body [wibble template [Sif html $def]]
  wibble template [Sif html {
    fieldset.ui-widget-content.ui-corner-all
      legend>b
        % if {$var ne ""}
          span.regcode/data-bind=text:$var: ?
          : :
        : $label
      : $body
  }]
}
