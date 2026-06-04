#!/usr/bin/env bash
set -e
set -o pipefail
set -u
shopt -s inherit_errexit

# git-create-task.sh
#
# Description
# - Creates a local working directory and a new Git branch for a given Jira task,
#   then pushes that branch to origin and sets the upstream.
#
# Synopsis
#   git-create-task.sh <TASK_KEY> <PROJECT_DIR_NAME>...
#
# Arguments
# - TASK_KEY            Jira key (e.g., ABC-123). Used to derive the branch name.
# - PROJECT_DIR_NAME... One or more project directory names (or git@ SSH URLs). Each is
#                       cloned via `git cwc` into the task directory and branched
#                       independently.
#
# Behavior
# - Looks up the Jira task summary via `acli` and sanitizes it to form a readable
#   branch suffix (punctuation removed, spaces converted to underscores).
# - Constructs a branch name: "<TASK_KEY>.<sanitized_summary>".
# - Creates and enters a directory named after the branch.
# - For each PROJECT, runs `git cwc <project>` to clone/checkout a working copy under
#   that directory, then creates and switches to the new branch in the project repo and
#   pushes it to origin with upstream tracking.
# - Prints one "<task_slug>/<project>" workspace path per project to stdout; git and
#   diagnostic output goes to stderr.
#
# Requirements
# - `acli` (Atlassian CLI) with Jira access configured.
# - `jq` and `sed` for processing JSON and text.
# - `git` and an authenticated remote named `origin`.
# - A custom command `git cwc` available in PATH (used to create/checkout a cached
#   working copy of the specified project directory).
# - macOS (path to bash and Chrome usage in other scripts suggests this environment).
#
# Notes
# - This script assumes `git cwc <project>` creates a subdirectory `<project>` in the
#   current directory; adjust if your `git cwc` behaves differently.
# - No validation is performed on arguments or tool availability; ensure prerequisites
#   are installed.
#
# Example
#   ./git-create-task.sh ABC-123 my-repo other-repo
#     -> creates branch directory ABC-123.<summary>
#     -> prepares my-repo and other-repo, creating/pushing branch ABC-123.<summary> in each
#     -> prints "ABC-123.<summary>/my-repo" and "ABC-123.<summary>/other-repo"

# shellcheck source=task.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/task.shlib"
# shellcheck source=project.shlib
. "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/project.shlib"

task="$(get_task "$1")"
readonly task

task_slug="$(get_task_slug "${task}")"
readonly task_slug

readonly dir="${task_slug}"
readonly branch="${task_slug}"

original_dir="${PWD}"
readonly original_dir
original_perms="$(stat -f %Lp .)"
readonly original_perms

_cleanup() {
  cd "${original_dir}" >/dev/null
  chmod "${original_perms}" .
}
trap _cleanup EXIT

chmod u+w .
mkdir -p "${dir}"
cd "${dir}" >/dev/null

for project_arg in "${@:2}"; do
  project="$(get_project "${project_arg}")"

  git cwc "${project_arg}" 1>&2

  (
    cd "${project}" >/dev/null
    git bud "${branch}" 1>&2
    git config "branch.${branch}.jira-task" "${task}"
  )

  echo "${task_slug}/${project}"
done
