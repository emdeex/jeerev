DEVELOPMENT NOTES
=================

> This file contains some preliminary notes about JeeMon and JeeRev, until I
  figure out where and how to maintain the documentation for this project.

How things fit together
-----------------------

JeeMon is the "runtime": the application-*independent* but platform-*dependent*
part of the system. Windows, Mac OS X, and Linux builds are available.

JeeRev has the main infra-structure supporting all the features one might need
to connect and control external devices (the *Physical Computing* part), and to
build self-contained long-running home monitoring and management solutions.

There is always one "latest" version of JeeRev at any point in time, and it
should work on all platforms for which there exists a JeeMon runtime. JeeRev can
be present either as a single file called `jeemon-rev` or - *for development
purposes* - as directory called `kit`. Without JeeRev, JeeMon is of little use.

Apart from these two core pieces, you will need files to make them do something
useful. This can range from a simple `main.tcl` file with a few lines of code to
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
follow all the latest changes, is to use `git` to check out a live copy. The
live copy includes the `kit` directory, so it's ready for use out of the box.

> Note: from now on, the **combination** of JeeMon and JeeRev will be called
**JeeMon** (!) - with the understanding that most of the software being written
is actually inside `jeemon-rev` (and `kit`). IOW, software development happens
mostly in the **JeeRev** project on GitHub, but the whole system is still called
**JeeMon**. JeeMon makes it all sing, JeeRev just dances along and evolves.

Design goals
------------

JeeMon is being used to create a reasonably elaborate *home monitoring* and
*home automation* system. I'm also using it to implement the PC-side of various
Physical Computing projects floating around here at JeeLabs.

I have several goals for this which I consider to be at the top of the list:

* trivial install - no update or dependency hell, no software conflicts
* should run well on mainstream Windows, Mac OS X, and Linux desktops
* will scale down and still be very practical on a low-end Linux box/board
* the main application interface is through a modern HTML5 / CSS3 web browser
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
* local network: TCP/IP for web sessions and UDP for broadcasting
* real-time communication with the browser: Server-Side Events

Directory overview
------------------

This is the structure of the development area in the code repository:

    drivers/      this is where drivers for various devices are found
    examples/     some self-contained examples
      hello-web   probably the simplest example of them all
      ...         each example can be run with `jeemon example/<dirname>`
    kit/          all the core code, can be wrapped up as a `jeemon-rev` file
      main.tcl    this is the first file executed by the jeemon runtime
      ...         most files are Tcl scripts which get auto-loaded on demand
    macosx/       files to build jeemon as a GUI application on Mac OS X
    tests/        test suites for (so far only a small) part of the code
    Makefile      helps with a few common tasks during development
    NOTES.md      this document
    README.md     as shown at the bottom of http://github.com/jcw/jeerev

Concepts
--------

Much of this is still *totally* in flux, but a first few patterns and choices
are nevertheless starting to emerge:

**Rigs** - The core logic on the server side is written in the form of "rigs".
These are Tcl scripts which are loaded in a specific way (similar to Python
modules, in fact). The two main features are that these rigs are "auto-loaded"
on first use (and can be re-loaded into a running system when the source file
has been edited), and that each rig is loaded into its own namespace, which
turns out to make them act quite a bit like singleton objects.

**Loadable drivers** - To support an endless (and ever-changing) range of
devices, each device can be associated with a specific piece of code. Devices
can be added, changed, replaced, and removed without having to restart the
application. Well, that's the plan - for now I'm just focusing on changing /
replacing drivers on the fly, to help with quick development and debugging.

**Events** - Devices generate local events, one per incoming message. Messages
can be lines of text, network packets, binary data, message batches, anything.
Events then get dispatched to one or more drivers to decode their content (for
incoming readings), or to lead to some external action (for outgoing commands).

**State variables** - Once decoded, a driver can submit results in the form of
readings, each of which gets stored as a state variable with a specific name.
The name is a "path" in that it consists of one or more nested identifiers,
joined with colons (e.g. `reading:weathernode:temp`). Values can be anything -
numbers, strings, binary data, images (Tcl values are conceptually untyped).

**Publish / subscribe** - State variable changes are published locally within
the application (and optionally also over the network to other applications).
Any part of the code can subscribe to changes, using a pattern to select the
subset it is interested in. When triggered, the code can access the new and old
values of any state variable, as well as a few associated timestamps.

**Hooks** - For triggers which are not related to state variables, there are
"hooks" (very similar to what the Drupal CMS offers) which allow different parts
of an application to respond to specific changes (e.g. code reloads, config
changes, file changes, data triggers), and to pass around arbitrary information.
Defining a hook is a matter of defining a proc with a certain naming convention
(two or more uppercase identifiers separated by periods). Calling them is done through the `app hook ...` function.

Drivers
-------

Drivers deal with "readings" coming into JeeMon and with "commands" going out.
The `radioBlip` driver is a simple example - it decodes data from a JeeNode
sending out wireless packets once a minute, containing a 4-byte sequence number:

    Jm doc "Decoder for the radioBlip sketch."

    proc decode {event raw} {
      Driver bitSlicer $raw ping 32
      $event submit ping $ping age [/ $ping [/ 86400 64]]
    }

The `Jm doc ...` line is recommended, it documents the purpose of this driver.
By declaring a `decode` proc, the driver signals that it is able to decode
incoming data. The actual association with one or more devices will be made
elsewhere, using a call to `Driver register ...`.

The first parameter is always an event object. The remaining args will be set to
fields from the event when called, in this case the driver is only interested in
a field called `raw`.

`Driver bitSlicer ...` is a utility function to extract individual bits from a
raw binary value. In this case a single local variable called `ping` will be
set to the first 32 bits of data, interpreted as a little-endian integer.

`$event submit ...` reports decoded information back to the driver subsystem -
in this case as two variables, `ping` and `age`. Age is just the ping count
converted to a number of days - drivers can sumbit any info they like.

That's all there is to it, although most drivers will require a bit more logic
to decode incoming data and turn it into submitted values.

All values end up in *state variables*, and each incoming packet will adjust
these state variables. Some results from two packets on my test setup:

    reading:RF12-868.5.3:radioBlip:ping = 482284
    reading:RF12-868.5.3:radioBlip:age = 357

    reading:RF12-868.5.3:radioBlip:ping = 482285
    reading:RF12-868.5.3:radioBlip:age = 357

As you can see, the full name of each associated state variable also includes
the type of information, where the data came from, and the driver name.

There are many types of drivers. Most will be similar to *radioBlip* and decode
one event into a small set of useful values. A few drivers will accept data from
different sources (e.g. serial or wireless for the *roomNode* driver).

A driver can also act as gateway and generate events as needed, as with the
*RF12demo* driver which turns each received line starting with "OK" into a new
event, and then dispatches each one to a *different* driver. Drivers can also
choose to submit an entire data structure for each incoming event, such as the
*ookRelay2* driver which recognizes several types of messages, even multiple
ones merged into a single packet.

Everything described so far is for incoming data such as sensor readings.
Outgoing commands have not yet been implemented.

Dynamic processing
------------------

JeeMon applications should be able to run for a long time (months & years) with
as little disruption as possible. The goal is not to implement a web site where
you browse from page to page, refreshing them along the way to see changes, but
to end up with a "live" system, where everything shown in the browser reflects
the actual situation in real time. If a temperature is shown, then it's the
*actual temperature*. If current values are shown in a graph, then that graph
should adjust when these values change. If a new device is plugged in, then it
should show up while you're looking at the list of devices.

There is much more to it than that, however. If a new version of a driver is
available, then it should be possible to switch to that new version without
having to restart the system or otherwise interrupt current processing. If the
configuration of any aspect of the system is changed, then it should *ripple
through* to adjust everything that's running and everything that's being shown.
Taken to extremes, this comes down to implementing a spreadsheet-like dataflow
mechanism, but for the entire application.

My first goal is simply to get the dynamics right to help speed development as
much as possible. Source code managed in the form of "rigs" is written in such a
way that it can be reloaded into a running system (most of the time). To avoid
continuous scanning across the entire source code base, and to avoid more clever
systems (which will add complexity), I usually set up an application to update
itself on each explicit page refresh in the browser. This makes the edit / run
cycle of software development pretty quick, because it lets me stay focused on
the task at hand, without having to relaunch and get back to the same situation.
For some tasks where this doesn't work well, I use test suites.

Apart from source code reloading for development, there are several ways in
which dynamic processing permeates all aspects of a JeeMon application:

* Incoming readings and outgoing commands are based on event objects, which are
  created and dispatched as needed.

* Much of the more interesting real-time activity ends up in *state variables*,
  which support a publish / subscribe mechanism. This means that any part of the
  code can keep track of changes of one or more matched state variables.

* For the other cases, *hook procs* can be defined. This too is a notification
  mechanism, but it's even easier to, eh, hook into: just define the proc inside
  a rig, and it'll get called whenever another part of the application triggers
  using that same name. Hooks can be used to *distribute* as well as *collect*
  data, without the sender or receiver having to know anything about each other.

* To notify web browsers of changes, "Server-Sent Events" are used. This is much
  simpler than "WebEvents", mostly because it's only uni-directional, i.e. from
  server to client(s). It works by keeping a special socket open, on which small
  messages are sent in real time. Most modern browsers now support SSE.

* For the reverse, i.e. clients notifying the server of changes, plain Ajax
  calls are used. This mechanism is considerably less important in this context,
  since the most common uses are for continuous monitoring and visualization
  with only *occasional* interaction to control and configure the system.

* With JavaScript on the client side, and libraries such as jQuery, jQuery UI,
  Knockout, DataTables, Raphael, and Flot, highly dynamic web pages have become
  easier than ever. This also makes it practical to use very low-end servers.

It looks like jQuery + SSE + Knockout will make it easy to accomplish the main
goal of supporting very dynamic and responsive web pages. All the hard work has
been done by now, and all the modern browsers will be able to handle such pages.
