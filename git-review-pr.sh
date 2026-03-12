#!/usr/bin/env bash
# shellcheck disable=SC2155
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# review pr

readonly GIT_DOMAIN
readonly GIT_ORG

readonly PR_URL="$(echo "$1"  | sed -E 's|(.*/pull/[^/]+).*|\1|')"

readonly REPO="$(echo "${PR_URL}" | sed -e "s|^https://${GIT_DOMAIN}/\(.*\)/pull/.*$|\1|")"
readonly PR="$(basename "${PR_URL}")"

readonly PROJECT="$(basename "${REPO}")"
readonly BRANCH="$(gh pr view "${PR}" --repo "${REPO}" --json headRefName --template "{{.headRefName}}")"

readonly REPO_URL="git@${GIT_DOMAIN}:${GIT_ORG}/${PROJECT}.git"

(
  mkdir -p "${BRANCH}"
  cd "${BRANCH}"

  git clone-or-pull --single-branch "${REPO_URL}"
  cd "${PROJECT}"

  git config --add remote.origin.fetch "+refs/heads/${BRANCH}:refs/remotes/origin/${BRANCH}"
  git fetch origin "${BRANCH}"
  git switch "${BRANCH}"
)
