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
to connect and control external devices (the *Physical Computing* part), and to
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

Since the move to GitHub (Aug 2011), JeeMon + JeeRev are in active developement.
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

Directory overview
------------------

This is the structure of the development area in the code repository:

    drivers/      this is where drivers for various devices are found
    examples/     some self-contained examples
      hello-web   probably the simplest example of them all
      ...         each example can be run with "jeemon example/<dirname>"
    kit/          all the core code, can be wrapped up as a "jeemon-rev" file
      main.tcl    is the first file executed by the jeemon runtime
      ...         most files are Tcl scripts which get auto-loaded on demand
    macosx/       files to build jeemon as a GUI application on Mac OS X
    tests/        test suites for (so far only a small) part of the code
    Makefile      helps with a few comon tasks during development
    NOTES.md      this document
    README.md     as shown at the bottom of http://github.com/jcw/jeerev

Concepts
--------

Much of this is still *totally* in flux, but a first few patterns and choices
are nevertheless starting to emerge:

**Rigs** - The core logic on the server side is written in the form of "rigs".
These are Tcl scripts which are loaded in a specific way (similar to Python
modules, in fact). The two main aspects are that these rigs are "auto-loaded" on
first use (and can be re-loaded into a running system when the source file has
been edited), and that each rig is loaded into its own namespace, which turns
out to make them act quite a bit like singleton objects.

**Loadable drivers** - To support an endless (and ever-changing) range of
devices, each device can be associated with a specific piece of code. Devices
can be added, changed, replaced, and removed without having to restart the
application. Well, that's the plan - for now I'm just focusing on changing /
replacing drivers on the fly, to help with quick development and debugging.

**Events** - Drivers generate local events, one per incoming message. Messages
can be lines of text, network packets, binary data, message batches, anything.
Events then get dispatched to one or more drivers to decode their content (for
incoming readings), or to lead to some external effect (for outgoing actions).

**State variables** - Once decoded, a driver can submit results in the form of
readings, each of which gets stored as a state variable with a specific name.
The name is a "path" in that it consists of one or more nested identifiers,
joined with colons (e.g. "readings:weathernode:temp"). Values can be anything -
numbers, strings, binary data, images (Tcl values are conceptually untyped).

**Publish / subscribe** - State variable changes are published locally within
the application (and optionally also over the network to other applications).
Any part of the code can subscribe to changes, using a pattern to select the
subset it is interested in. When triggered, the code can access the new and old
values of any state variable, as well as a few associated timestamps.

**Hooks** - For triggers which are not related to state variables, there are
"hooks" (very similar to what the Drupal CMS offers) which allow different parts
of an application to respond to specific changes (e.g. code reloads, config
changes, file changes, data changes), and to pass around information in very
open-ended ways. Defining a hook is a matter of defining a proc with a certain
naming convention (two or more uppercase identifiers separated by periods).
