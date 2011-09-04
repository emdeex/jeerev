Most examples in this directory should work out of the box, but you may have to
adjust a configuration file (called `config.txt`) to match your setup:

1. Copy `config-sample.txt` to `config.txt` (if it exists) and edit as needed.
2. Run the code by typing `jeemon examples/<dirname>` from the JeeRev dir.
3. There is no step 3.

Examples
--------

* **hello-web** - The simplest possible web server.
* **hello-rf12** - Collect and display data from a JeeNode running RF12demo.
* **kaku-send** - Send a command to the KlikAanKlikUit remote control.
* **peek-demo** - Peeking into a running system to see vars, procs, etc.
* **update-demo** - Demonstrate real-time web updates using Server-Sent Events.
* **collectd-demo** - Listen for 'collectd' info on the std UDP multicast port.
* **driver-demo** - How to decode messages coming from a JeeLink with RF12demo.
* **replay-demo** - This example replays messages which were recorded earlier.
* **webfeed-demo** - How to feed readings into state variables via web requests.
* **table-demo** - Show readings as table in a browser with real-time updates.
* **history-test** - Collect some data to test the round-robin storage logic.
* **graph-demo** - Show recent temperatures as graph in the browser.
* **tree-demo** - Display all state variables as a tree in the browser.
