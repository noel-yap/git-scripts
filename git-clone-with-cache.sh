#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# shellcheck source=branch.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/branch.shlib"

# shellcheck source=cache.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/cache.shlib"

if [[ "$1" == git@* && "$1" == *.git ]]; then
  git_domain="${1#git@}"
  git_domain="${git_domain%%:*}"
  git_org="${1#*:}"
  git_org="${git_org%/*}"
  project="${1##*/}"
  project="${project%.git}"
else
  git_domain="${GIT_DOMAIN}"
  git_org="${GIT_ORG}"
  project="$1"
fi
readonly git_domain
readonly git_org
readonly project

readonly cache_root="${HOME}/.cache/git/${git_domain}/${git_org}"

readonly remote_fetch_url="${cache_root}/${project}"
readonly remote_push_url="git@${git_domain}:${git_org}/${project}.git"

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
  git remote add upstream "${remote_push_url}"
  git fetch upstream "$(get_trunk)"
)
