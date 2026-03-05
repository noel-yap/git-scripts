#!/bin/bash

set -e
set -o pipefail
set -u

if ! git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null
then
  git init
else
  branch="$1"

  parent="$(git branch --show-current)"
  union="$(git rev-parse HEAD)"

  git branch "${branch}"
  git config "branch.${branch}.parent" "${parent}"
  git config "branch.${branch}.union" "${union}"
fi
