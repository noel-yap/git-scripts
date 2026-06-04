#!/usr/bin/env bash
# shellcheck disable=SC2155
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# review pr

readonly GIT_DOMAIN

# shellcheck source=string.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/string.shlib"

readonly PR="$(echo "$1" | sed -E 's|.*/pull/([^/?#]+).*|\1|')"
readonly PR_URL="$(echo "$1" | sed -E 's|(.*/pull/[^/?#]+).*|\1|')"

readonly REPO="$(echo "${PR_URL}" | sed -e "s|^https://${GIT_DOMAIN}/\(.*\)/pull/.*$|\1|")"

readonly PROJECT="$(basename "${REPO}")"
readonly BRANCH="$(gh pr view "${PR}" --repo "${REPO}" --json headRefName --template "{{.headRefName}}")"
readonly BRANCH_DIR="$(unicodify_punctuation "${BRANCH}")"

(
  mkdir -p "${BRANCH_DIR}"
  cd "${BRANCH_DIR}"

  git cwc "$1"
  cd "${PROJECT}"

  git config --add remote.upstream.fetch "+refs/heads/${BRANCH}:refs/remotes/upstream/${BRANCH}"
  git fetch upstream "${BRANCH}"
  git switch "${BRANCH}"

  pwd
)
