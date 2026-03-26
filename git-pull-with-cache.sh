#!/usr/bin/env bash
# shellcheck disable=SC2155
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# shellcheck source=branch.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/branch.shlib"

readonly remote_pull_url="$(git remote get-url origin)"

(
  cd "${remote_pull_url}"
  git pull
)

git pull origin "$(get_trunk)"
