JeeRev
======

JeeRev is the core library for use with [JeeMon][1], containing the generic code
needed to create applications for Physical Computing and Home Automation.

For more information about JeeRev, see the (old'ish) [JeeRev home page][2] and
the (new) [development notes][3].

Download
--------

There are three ways to get these files and use them with JeeMon:

  1. Run `jeemon` to download the wrapped `jeemon-rev` from a fixed [URL][4]
  2. Download the latest [zip][5] or [tar][6] archive snapshot and unpack it
  3. Fetch from GitHub using *git*: `git clone git://github.com/jcw/jeerev.git`

Usage
-----

To run in development mode with all the JeeRev files unpacked, `jeemon` must be
launched from this top-level directory so it sees the `kit/main.tcl` file.

Otherwise, the latest `jeemon-rev` release will automatically be downloaded by
JeeMon on startup. The download site at JeeLabs is <http://dl.jeelabs.org/>. To
download an updated version, delete the `jeemon-rev` file and relaunch JeeMon.

The `examples` directory contains some apps to illustrate the basic features.

To run the test suites, type `make test`.

To generate a `jeemon-rev` file release, type `make wrap`.

  [1]: http://jeelabs.org/jeemon
  [2]: http://jeelabs.org/jeerev
  [3]: https://github.com/jcw/jeerev/blob/master/NOTES.md
  [4]: http://dl.jeelabs.org/jeemon-rev
  [5]: https://github.com/jcw/jeerev/zipball/master
  [6]: https://github.com/jcw/jeerev/tarball/master
