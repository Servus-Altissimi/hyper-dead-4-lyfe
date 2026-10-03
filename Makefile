PY ?= python3

.PHONY: all build test install uninstall install-tests assets clean

all: build

build:
	$(PY) -m tools build

test:
	$(PY) -m tools test

install:
	$(PY) -m tools install

uninstall:
	$(PY) -m tools uninstall

install-tests:
	$(PY) -m tools install-tests

assets:
	$(PY) -m tools assets

clean:
	$(PY) -m tools clean
