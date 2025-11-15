#!/opt/homebrew/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

readonly task="$1"
readonly project="$2"

readonly branch="${task}"

mkdir -p "${branch}"
cd "${branch}"
git cwc "${project}"

(
  cd "${project}"
  git switch -c "${branch}"
  git push --set-upstream origin "${branch}"
)
