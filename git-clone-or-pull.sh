#!/bin/bash

set -e
set -o pipefail
set -u

readonly USAGE_STRING="$0 [«GIT_OPT»…] «REPO_URL» [«DIR»]"

GIT_OPTS=()
while [[ "$1" != *.git ]]; do
  GIT_OPTS+=("$1")
  shift
done
readonly GIT_OPTS

readonly REPO_URL="$1"
if [[ "${REPO_URL}" == file://* ]]; then
  readonly DEFAULT_DIR="$(basename "$(dirname "${REPO_URL}")")"
else
  readonly DEFAULT_DIR="$(basename "${REPO_URL}" .git)"
fi
readonly DIR="${2-${DEFAULT_DIR}}"

if [[ -d "${DIR}" ]]; then
  (
    cd "${DIR}"
    git pull
  )
else
  git clone ${GIT_OPTS[@]-} "${REPO_URL}" "${DIR}"
fi
