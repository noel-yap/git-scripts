#!/bin/bash

set -e
set -o pipefail
set -u

if ! git diff --cached --exit-code; then
  echo ERROR: Uncommitted changes. Exiting. >&2
  exit 1
fi

if [[ "$1" == *..* ]]; then
  range="$1"

  upper_commit="${1#*..}"
  branch="$(git rev-parse --abbrev-ref "${upper_commit}" 2>/dev/null)"
else
  branch="$1"

  range="HEAD..${branch}"
fi

commits=($(git log --pretty=format:"%h" "${range}" | tac))

git branch -D "${branch}"
git switch -c "${branch}"

for commit in "${commits[@]}"; do
  git cherry-pick "${commit}"
done
