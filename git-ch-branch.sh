#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# shellcheck source=branch.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/branch.shlib"

readonly USAGE_STRING="$0 [«BRANCH_NAME»]"

if [[ $# -gt 0 ]]; then
  BRANCH_NAME="$1"
  shift

  if [[ "${BRANCH_NAME}" == '-' ]]; then
    BRANCH_NAME='@{-1}'
  fi
else
  BRANCH_NAME="$(get_trunk)"
fi

git switch -- "${BRANCH_NAME}"
