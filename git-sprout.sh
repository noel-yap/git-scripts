#!/bin/bash

set -e
set -o pipefail
set -u

if ! git rev-parse --is-inside-work-tree 2>/dev/null
then
  git init
else
  branch="${USER}/$1"

  git switch -c "${branch}"
fi
