JEEMON = jeemon
DISTDIR = bussie:/home/pub/jeelabs.org/

all: tabcheck test

# run the test suites
test:
	$(JEEMON) tests

# fail if there are text files with tabs in them
tabcheck:
	grep -rlI --exclude=Makefile "	" *; test $$? = 1

# generate a wrapped file from the "kit" directory
wrap:
	$(JEEMON) kit/wrapup.tcl

# this target is for private use only
dist: tabcheck test wrap
	rsync -a jeemon-rev $(DISTDIR)

# called on F6 by TextMate on MacOSX to refresh the current window in Camino
testmate:
	osascript -e 'tell application "Camino"' \
		  -e 'open location (get URL of current tab of window 1)' \
	  	  -e 'end tell'

clean:
	rm -rf jeemon-rev
