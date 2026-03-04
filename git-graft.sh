#!/opt/homebrew/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

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

  range="${branch}~..${branch}"
fi

mapfile -t commits < <(git log --pretty=format:"%h" "${range}" | tac)
echo "grafting ${commits[*]}"

git shear "${branch}"
git bud "${branch}"

for commit in "${commits[@]}"; do
  git cherry-pick "${commit}"
done
