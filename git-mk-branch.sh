#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

if ! git rev-parse --is-inside-work-tree >/dev/null 2>/dev/null
then
  git init
else
  parent=''
  branch=''
  for arg in "$@"; do
    case "${arg}" in
      --parent=TRUNK)
        parent="$(git config init.defaultBranch)"
        ;;
      --parent=*)
        parent="${arg#--parent=}"
        ;;
      *)
        branch="${arg}"
        ;;
    esac
  done
  readonly branch

  if [[ -z "${parent}" ]]; then
    parent="$(git branch --show-current)"
  fi
  if [[ -z "${parent}" ]]; then
    echo 'parent must be set; use --parent' >&2
    exit 1
  fi
  union="$(git rev-parse HEAD)"

  git branch "${branch}"
  git config "branch.${branch}.parent" "${parent}"
  git config "branch.${branch}.union" "${union}"
fi
