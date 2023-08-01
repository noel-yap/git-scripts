#!/bin/bash

(
  cd "${HOME}/.cache/grail"

  git pull
)

branch="$(git rev-parse --abbrev-ref HEAD)"
git switch master
git pull origin master
git switch "${branch}"
git rebase master
