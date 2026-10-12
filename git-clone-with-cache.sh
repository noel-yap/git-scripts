#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# shellcheck source=branch.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/branch.shlib"

# shellcheck source=cache.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/cache.shlib"

# shellcheck source=git-clone-with-cache.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/git-clone-with-cache.shlib"

# shellcheck source=share-claude-memory.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/share-claude-memory.shlib"

eval "$(get_repo_coordinates "$1")"
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
  shared_memory_dir="$(get_shared_claude_memory_dir "${cache_root}/${project}")"
  write_auto_memory_setting "${PWD}" "${shared_memory_dir}"
  ignore_claude_local_settings "${PWD}"
)
