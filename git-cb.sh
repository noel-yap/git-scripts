#!/opt/homebrew/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

readonly USAGE_STRING="$0 [«BRANCH_NAME»]"

if [[ $# -gt 0 ]]; then
  BRANCH_NAME="$1"
  shift

  if [[ "${BRANCH_NAME}" == '-' ]]; then
    BRANCH_NAME='@{-1}'
  fi
else
  BRANCH_NAME="$(git config --get init.defaultBranch)"
fi

git switch "${BRANCH_NAME}"
