#!/bin/bash

set -e
set -o pipefail
set -u

if ! git rev-parse --is-inside-work-tree 2>/dev/null
then
  git init
  git config --local branch.trunk "$(git config --get init.defaultbranch)"
else
  branch="${USER}/$1"

  git switch -c "${branch}"
fi
