#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

git branch -D -- "$@"
