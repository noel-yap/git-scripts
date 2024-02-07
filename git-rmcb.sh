#!/bin/bash

set -e
set -o pipefail
set -u

readonly USAGE_STRING="$0 «BRANCH_NAME»"

BRANCH_NAME="$1"
shift

git shear "${BRANCH_NAME}"
git mcb "${BRANCH_NAME}"
