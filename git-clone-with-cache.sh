#!/opt/homebrew/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

readonly GIT_DOMAIN
readonly GIT_ORG

readonly project="$1"

readonly cache_dir="${HOME}/.cache/git/${GIT_DOMAIN}/${GIT_ORG}"

readonly remote_fetch_url="${cache_dir}/${project}"
readonly remote_push_url="git@${GIT_DOMAIN}:${GIT_ORG}/${project}.git"

(
  mkdir -p "${cache_dir}"
  cd "${cache_dir}"
  git clone-or-pull "${remote_push_url}"
)

git clone-or-pull "${remote_fetch_url}"

(
  cd "${project}"
  git remote set-url --push origin "${remote_push_url}"
)
