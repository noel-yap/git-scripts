#!/opt/homebrew/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

# create pr

export CHROME_PROFILE

git push
gh pr create --fill --head="$(git branch --show-current)"

# shellcheck disable=SC2155
readonly PR_URL="$(gh pr view --json url --jq .url)"

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --new-window \
    --profile-directory="${CHROME_PROFILE}" \
    "${PR_URL}"
