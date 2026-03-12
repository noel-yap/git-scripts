#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

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
