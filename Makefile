JEEMON = jeemon
DISTDIR = bussie:/home/pub/jeelabs.org/

test:
	$(JEEMON) tests

wrap:
	$(JEEMON) wrapup.tcl

# this target is for private use only
dist: test wrap
	rsync -a jeemon-rev $(DISTDIR)

clean:
	rm -rf jeemon-rev
