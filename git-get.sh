#!/bin/bash

if [ $# -lt 2 ]; then
  remote='origin'
else
  remote="$1"
  shift
fi
branch="$1"

git fetch "${remote}" "${branch}:${branch}"
git switch "${branch}"
