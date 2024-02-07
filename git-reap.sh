#!/bin/bash

(
  cd "${HOME}/.cache/grail"

  git pull
)

branch="$(git rev-parse --abbrev-ref HEAD)"
trunk="$(git config --get branch.trunk)"

git switch "${trunk}"
git pull origin "${trunk}"
git switch "${branch}"
git rebase "${trunk}"
