#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# shellcheck source=branch.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/branch.shlib"

# shellcheck source=cache.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/cache.shlib"

(
  cd "$(get_cache_dir)"

  git pull
)

branch="$(git rev-parse --abbrev-ref HEAD)"
trunk="$(get_trunk)"

git switch "${trunk}"
git pull origin "${trunk}"
git graft "${branch}"
