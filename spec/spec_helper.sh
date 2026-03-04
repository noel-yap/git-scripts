# shellcheck shell=sh

# Defining variables and functions here will affect all specfiles.
# Change shell options inside a function may cause different behavior,
# so it is better to set them here.
set -eu

export PROJECT_ROOT_DIR
PROJECT_ROOT_DIR="$(git rev-parse --show-toplevel)"

# This callback function will be invoked only once before loading specfiles.
spec_helper_precheck() {
  # Available functions: info, warn, error, abort, setenv, unsetenv
  # Available variables: VERSION, SHELL_TYPE, SHELL_VERSION
  : minimum_version "0.28.1"
}

# This callback function will be invoked after a specfile has been loaded.
spec_helper_loaded() {
  :
}

# This callback function will be invoked after core modules has been loaded.
spec_helper_configure() {
  # Available functions: import, before_each, after_each, before_all, after_all
  : import 'support/custom_matcher'
}

# Source library functions under test
# shellcheck source=../external/bash-mock/in-tempdir.shlib
. "${PROJECT_ROOT_DIR}/external/bash-mock/in-tempdir.shlib"

# shellcheck source=../external/bash-mock/mock-first-with-rest.shlib
. "${PROJECT_ROOT_DIR}/external/bash-mock/mock-first-with-rest.shlib"

# shellcheck source=repo.shlib
. "${PROJECT_ROOT_DIR}/spec/repo.shlib"
