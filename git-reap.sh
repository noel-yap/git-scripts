#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

(
  cd "${HOME}/.cache/grail"

  git pull
)

branch="$(git rev-parse --abbrev-ref HEAD)"
trunk="$(git config --get init.defaultBranch)"

git switch "${trunk}"
git pull origin "${trunk}"
git switch "${branch}"
git rebase "${trunk}"
