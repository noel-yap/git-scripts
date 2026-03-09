#!/bin/bash

set -e
set -o pipefail
set -u

readonly USAGE_STRING="$0 «BRANCH_NAME»"

branch=''
for arg in "$@"; do
  case "${arg}" in
    --*) ;;
    *) branch="${arg}" ;;
  esac
done
readonly branch

git mb "$@"
git cb "${branch}"
