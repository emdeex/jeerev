DEVELOPMENT NOTES
=================

> This file contains some preliminary notes about JeeMon and JeeRev, until I
  figure out where and how to maintain the documentation for this project.

How things fit together
-----------------------

JeeMon is the "runtime": the application-*independent* but platform-*dependent*
part of the system. Several Windows, Mac OS X, and Linux versions are supported.
Get it once and then keep it around. Don't use a version older than August 2011.

JeeRev has the main infra-structure supporting all the features one might need
to connect and control external devices (the *Physicai Computing* part), and to
build self-contained long-running home monitoring and management solutions.

There is always one "latest" version of JeeRev at any point in time, and it
should work on all platforms for which there exists a JeeMon runtime. JeeRev can
be present either as a single file called "jeemon-rev" or - *for development
purposes* - as directory called "kit". Without JeeRev, JeeMon is of little use.

Apart from these two core pieces, you will need files to make them do something
useful. This can range from a simple "main.tcl" file with a few lines of code to
a whole set of configuration files, drivers, webpages, images, databases, etc.

Status
------

Since the move GitHub (August 2011), JeeMon + JeeRev are in active developement.
The code at [github.com](https://github.com/jcw) supercedes the code at JeeLabs
(but a lot is being reused). The [jeelabs.net](http://jeelabs.net/projects) site
now refers to older stuff, and its wikis + issue trackers are no longer updated.

The JeeMon core has only changed in minor ways since 2008. The current builds
are stable - no further changes are expected except for bug fixes and very minor
tweaks. Get it once from <http://jeelabs.org/pub/jeemon/> and then just keep it
around. Don't use a version older than August 2011.

JeeRev on the other hand is going to keep changing all the time. The only way to
keep track of it is via <https://github.com/jcw/jeerev>, and the easiest way to
follow all the latest changes, is to use "git" to check out a live copy. The
live copy includes a "kit" directory, so it's ready for use out of the box.

> Note: from now on, the **combination** of JeeMon and JeeRev will be called
**JeeMon** (!) - with the understanding that most of the software being written
is actually inside "jeemon-rev" (and "kit"). IOW, software development happens
mostly in the **JeeRev** project on GitHub, but the whole system is still called
**JeeMon**. JeeMon makes it all work, JeeRev just dances around and evolves.

Design goals
------------

JeeMon is being used to create a reasonably elaborate *home monitoring* and
*home automation* system. I'm also using it to implement the PC-side of various
Physical Computing projects floating around here at JeeLabs.

I have several goals for this which I consider at the top of the list:

* trivial install - no update or dependency hell, no software conflicts
* should run well on mainstream Windows, Mac OS X, and Linux desktops
* will scale down and still be very practical on a low-end Linux box/board
* the main application interface is through a modern HTML5/CSS3 web browser
* maximum modularity - designed to keep up with whatever needs I run into
* dynamic updating wherever possible, browser refresh is not "live" enough
* given the low-end constraints, much of the presentation will use JavaScript

Technologies
------------

So far, I have:

* on the server side: JeeMon implements the Tcl/Tk programming environment
* storage: plain text, Metakit database, custom binary data, and SQL bindings
* web server: Wibble (Tcl), coroutine-based, HTML 1.1, async I/O
* on the client side: JavaScript, HTML5, CSS3
* standard JavaScript libraries: jQuery, jQuery UI, Knockout, Flot, and more
* real-time communication with the browser: Server-Side Events
