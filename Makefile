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
	$(JEEMON) wrapup.tcl

# this target is for private use only
dist: tabcheck test wrap
	rsync -a jeemon-rev $(DISTDIR)

clean:
	rm -rf jeemon-rev
