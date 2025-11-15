#!/opt/homebrew/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

# create pr

gh pr create --fill
readonly PR_URL="$(gh pr view --json url --jq .url)"

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --new-window \
    --profile-directory='Profile 1' \
    "${PR_URL}"

exit 0

readonly REMOTE_PUSH_URL="$(git config --get remote.origin.pushurl)"
readonly BRANCH="$(git branch --show-current)"

readonly PR_URL="$(echo "${REMOTE_PUSH_URL}" | sed -e 's|^git@github.com:|https://github.com/|' -e "s|\.git$|/pull/new/${BRANCH}|")"

"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
    --new-window \
    --profile-directory='Profile 1' \
    "${PR_URL}"
