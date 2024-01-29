#!/bin/bash

set -e
set -o pipefail
set -u

git branch -D "$1"
