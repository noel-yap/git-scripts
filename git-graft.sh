#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

script_dir="$(dirname "$(realpath "${BASH_SOURCE[0]}")")"

# shellcheck source=branch.shlib
. "${script_dir}/branch.shlib"

if ! git diff --cached --exit-code; then
  echo ERROR: Uncommitted changes. Exiting. >&2
  exit 1
fi

if [[ $# -eq 0 ]]; then
  # graft all child branches onto current branch

  cwb="$(git branch --show-current)"
  mapfile -t child_branches < <(get_children_branches "${cwb}")
  readonly child_branches

  if [[ ${#child_branches[@]} -eq 0 ]]; then
    if [[ ${GIT_GRAFT_DEPTH:-0} -eq 0 ]]; then
      echo "ERROR: No child branches found for '${cwb}'. Use \`git bud\` to create sub-branches." >&2
      exit 1
    else
      echo "WARNING: No child branches found for '${cwb}'. If this is unexpected, use \`git bud\` to create sub-branches." >&2
    fi
  fi
  for child_branch in "${child_branches[@]}"; do
    (
      cwb="$(git branch --show-current)"
      # shellcheck disable=SC2064
      trap "git switch -- '${cwb}'" EXIT

      git graft "${child_branch}"
    )
  done
else
  if [[ "$1" == *..* ]]; then
    # graft explicit range
    range="$1"

    before() {
      :
    }

    after() {
      :
    }
  else
    # graft specific branch
    branch="$1"
    union="$(git config "branch.${branch}.union" || true)"
    if [[ -z "${union}" ]]; then
      echo "ERROR: No union found for '${branch}'. Use \`git bud\` to create branches." >&2
      exit 1
    fi

    range="${union}..${branch}"

    # fullwidth full stop used as a separator to avoid collisions
    fullwidth_full_stop='．'
    # tag is useful in case the grafting fails (eg due to a merge conflict)
    tag="${branch}${fullwidth_full_stop}original"

    before() {
      git tag -f "${tag}"
      echo "Created tag ${tag} ($(git rev-parse --short HEAD))"
      git branch -D -- "${branch}"
      git bud "${branch}"
    }

    after() {
      git tag -d "${tag}"
      GIT_GRAFT_DEPTH=$(( ${GIT_GRAFT_DEPTH:-0} + 1 )) git graft
    }
  fi

  mapfile -t commits < <(git log --pretty=tformat:"%h" "${range}" | tac)
  echo "grafting ${range}: ${commits[*]}"

  before

  for commit in "${commits[@]}"; do
    git cherry-pick --allow-empty --empty='keep' "${commit}"
  done

  after
fi
