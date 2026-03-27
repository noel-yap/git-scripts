#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# shellcheck source=cache.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/cache.shlib"

readonly GIT_DOMAIN
readonly GIT_ORG

readonly project="$1"

readonly cache_root="${HOME}/.cache/git/${GIT_DOMAIN}/${GIT_ORG}"

readonly remote_fetch_url="${cache_root}/${project}"
readonly remote_push_url="git@${GIT_DOMAIN}:${GIT_ORG}/${project}.git"

(
  mkdir -p "${cache_root}"
  cd "${cache_root}"
  git clone-or-pull "${remote_push_url}"
)

git clone-or-pull "${remote_fetch_url}"

(
  cd "${project}"
  set_cache_dir "${cache_root}/${project}"
  git remote set-url --push origin "${remote_push_url}"
)
