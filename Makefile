JMEXE = jeemon
MACGUI = JeeMon-MacGUI
DISTDIR = bussie:/home/pub/jeelabs.org/

all: tabcheck test

# run the test suites
test:
	$(JMEXE) tests
fulltest:
	$(JMEXE) tests -constraints slow

# fail if there are text files with tabs in them
tabcheck:
	grep -rlI --exclude=Makefile "	" *; test $$? = 1

# generate a wrapped file from the "kit" directory
wrap:
	$(JMEXE) kit/wrapup.tcl

# this target is for private use only
dist: tabcheck fulltest wrap
	rsync -a jeemon-rev $(DISTDIR)
	if [ -f $(MACGUI).zip ]; then rsync -a $(MACGUI).zip $(DISTDIR); fi

# called on F6 by TextMate on MacOSXh to refresh the current window in Camino
testmate:
	osascript -e 'tell application "Camino"' \
		  -e 'open location (get URL of current tab of window 1)' \
	  	  -e 'end tell'

clean:
	rm -rf jeemon-rev JeeMon.app $(MACGUI).zip
