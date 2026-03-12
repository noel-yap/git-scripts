#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

if [ $# -lt 2 ]; then
  remote='origin'
else
  remote="$1"
  shift
fi
branch="$1"

git fetch "${remote}" "${branch}:${branch}"
git switch "${branch}"
