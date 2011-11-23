**JeeRev** is the core library for use with [JeeMon][1], containing the generic
code needed to create applications for Physical Computing and Home Automation.

For more information about JeeRev, see the (old'ish) [JeeRev home page][2] and
the (new) [development notes][3].

Status
------

This is the development branch... *things change, break, and evolve here.*

Download
--------

There are three different ways to use the JeeRev code with JeeMon:

  1. Run `jeemon` and it'll download a wrapped `jeemon-rev` from [this URL][4]
  2. Download the latest [archive snapshot][5] from GitHub and unpack it
  3. Grab it from GitHub using git: `git clone git://github.com/jcw/jeerev.git`

Usage
-----

To run in development mode with all JeeRev files unpacked, `jeemon` must be
launched from JeeRev's top-level directory so it'll see a `kit/main.tcl` file.

Otherwise, the latest `jeemon-rev` release will automatically be downloaded by
JeeMon on startup. The download location is <http://dl.jeelabs.org/jeemon-rev>.
To update to a new version, delete the `jeemon-rev` file and relaunch JeeMon.

The `examples` directory contains a few apps to illustrate basic features.

To run the test suites, type `make test`.

If you want to generate a `jeemon-rev` file release yourself, type `make wrap`.

  [1]: http://jeelabs.org/jeemon
  [2]: http://jeelabs.org/jeerev
  [3]: https://github.com/jcw/jeerev/blob/master/NOTES.md
  [4]: http://dl.jeelabs.org/jeemon-rev
  [5]: https://github.com/jcw/jeerev/archives/master
  