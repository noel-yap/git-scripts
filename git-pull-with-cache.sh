#!/opt/homebrew/bin/bash -eu
# shellcheck disable=SC2155
set -o pipefail
shopt -s inherit_errexit

readonly remote_pull_url="$(git remote get-url origin)"

(
  cd "${remote_pull_url}"
  git pull
)

git pull origin "$(git config --get init.defaultBranch)"
