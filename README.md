JeeRev
======

JeeRev is the core library for use with [JeeMon][1], containing the generic code
needed to create applications for Physical Computing and Home Automation.

For more information about JeeRev, see the [JeeRev home page][2].

Usage
-----

To run in development mode with all the JeeRev files unpacked, `jeemon` must be
launched from this top-level directory so it can find the `kit/main.tcl` file.

Otherwise, the latest `jeemon-rev` release will automatically be downloaded by
JeeMon on startup. The download site at JeeLabs is <http://dl.jeelabs.org/>. To
download an updated version, delete the `jeemon-rev` file and relaunch JeeMon.

The `examples` directory contains some apps to illustrate the basic features.

To run the test suites, type `make test`.

To generate a `jeemon-rev` file release, type `make wrap`.

  [1]: http://jeelabs.net/projects/jeemon/wiki
  [2]: http://jeelabs.net/projects/jeerev/wiki
