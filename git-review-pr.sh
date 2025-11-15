#!/opt/homebrew/bin/bash -eu
set -o pipefail
shopt -s inherit_errexit

# review pr

readonly PR_URL="$1"

readonly REPO="$(echo "${PR_URL}" | sed -e 's|^https://github\.com/\(.*\)/pull/.*$|\1|')"
readonly PR="$(basename "${PR_URL}")"

readonly PROJECT="$(basename "${REPO}")"
readonly BRANCH="$(gh pr view "${PR}" --repo "${REPO}" --json headRefName --template "{{.headRefName}}")"

readonly REPO_URL="git@github.com:rzsoftware/${PROJECT}.git"

(
  mkdir -p "${BRANCH}"
  cd "${BRANCH}"

  git clone --single-branch --branch main "${REPO_URL}"
  cd "${PROJECT}"

  git config --add remote.origin.fetch "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"
  git fetch origin "${BRANCH}"
  git switch "${BRANCH}"
)
