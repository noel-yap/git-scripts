# Run the project's test suites.
#
# Shell libraries/scripts are tested with shellspec (spec/); the task.shlib
# pytest suite lives under tests/.

SHELLSPEC ?= shellspec
PYTEST ?= pytest

# Stamp recording that submodules were last synced. Lives under .git/ so it is
# never committed and is inherently per-clone. .gitmodules is its prerequisite,
# so the cached sync re-runs only when a submodule is added/removed or its URL/
# branch changes -- otherwise the stamp is newer and the sync is skipped.
SUBMODULE_STAMP := .git/.submodules-synced

.PHONY: test test-shell test-python submodules

# Default target: run everything.
test: test-shell test-python

# Force a submodule sync now, regardless of the cache stamp. Run this after a
# pull that moves a pinned submodule commit (which the cache does not detect).
# Drops the stamp and rebuilds it via the rule below, so the sync command lives
# in exactly one place.
submodules:
	@rm -f $(SUBMODULE_STAMP)
	@$(MAKE) --no-print-directory $(SUBMODULE_STAMP)

# Cached sync: runs only when out of date relative to .gitmodules.
$(SUBMODULE_STAMP): .gitmodules
	git submodule update --init --recursive
	@touch $@

# shellspec specs under spec/.
test-shell: $(SUBMODULE_STAMP)
	$(SHELLSPEC)

# pytest suites under tests/.
test-python: $(SUBMODULE_STAMP)
	$(PYTEST) tests/
