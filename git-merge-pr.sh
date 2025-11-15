#!/opt/homebrew/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

# merge pr

gh pr merge

