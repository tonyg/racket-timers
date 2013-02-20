PLANET_MAJOR=1
PLANET_MINOR=0
PLANET_VERSION=$(PLANET_MAJOR).$(PLANET_MINOR)
PLANET_NAME=timers
PLANET_USER=tonyg

all:

$(PLANET_NAME).plt: clean
	mkdir planet-build-temp
	(cd planet-build-temp; git clone .. $(PLANET_NAME))
	(cd planet-build-temp/$(PLANET_NAME); git checkout $(PLANET_NAME).plt-${PLANET_VERSION})
	(cd planet-build-temp; raco planet create $(PLANET_NAME))
	mv planet-build-temp/$(PLANET_NAME).plt .
	rm -rf planet-build-temp

setup: link
	raco setup -P $(PLANET_USER) $(PLANET_NAME).plt $(PLANET_MAJOR) $(PLANET_MINOR)

clean:
	rm -rf compiled doc
	rm -f $(PLANET_NAME).plt

link:
	raco planet link $(PLANET_USER) $(PLANET_NAME).plt $(PLANET_MAJOR) $(PLANET_MINOR) $(CURDIR)

unlink:
	raco planet unlink $(PLANET_USER) $(PLANET_NAME).plt $(PLANET_MAJOR) $(PLANET_MINOR)

tag:
	git tag $(PLANET_NAME).plt-${PLANET_VERSION}
