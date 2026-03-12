#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

readonly USAGE_STRING="$0 «BRANCH_NAME»"

BRANCH_NAME="$1"
shift

git rb "${BRANCH_NAME}"
git mcb "${BRANCH_NAME}"
