# Run the project's test suites.
#
# Shell libraries/scripts are tested with shellspec (spec/); the utils.shlib
# pytest suite lives under tests/.

SHELLSPEC ?= shellspec
PYTEST ?= pytest

.PHONY: test test-shell test-python

# Default target: run everything.
test: test-shell test-python

# shellspec specs under spec/.
test-shell:
	$(SHELLSPEC)

# pytest suites under tests/.
test-python:
	$(PYTEST) tests/