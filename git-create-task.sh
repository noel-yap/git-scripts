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
#   git-create-task.sh <TASK_KEY> <PROJECT_DIR_NAME>
#
# Arguments
# - TASK_KEY            Jira key (e.g., ABC-123). Used to derive the branch name.
# - PROJECT_DIR_NAME    Name of the project directory to work in (must be a subdir
#                       created by `git cwc` below).
#
# Behavior
# - Looks up the Jira task summary via `acli` and sanitizes it to form a readable
#   branch suffix (punctuation removed, spaces converted to underscores).
# - Constructs a branch name: "<TASK_KEY>.<sanitized_summary>".
# - Creates and enters a directory named after the branch.
# - Runs `git cwc <project>` to clone/checkout a working copy under that directory.
# - Creates and switches to the new branch in the project repo and pushes it to origin
#   with upstream tracking.
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
#   ./git-create-task.sh ABC-123 my-repo
#     -> creates branch directory ABC-123.<summary>
#     -> prepares my-repo and creates/pushes branch ABC-123.<summary>

readonly task="$1"
readonly project="$2"

summary="$(acli jira workitem view "${task}" --fields=summary --json | jq '.fields.summary' | sed -e "s|[[:punct:]]||g" -e 's| |_|g')"
readonly summary

readonly dir="${task}꞉${summary}"
readonly branch="${task}.${summary}"

mkdir -p "${dir}"
cd "${dir}"
git cwc "${project}"

(
  cd "${project}"
  git switch -c "${branch}"
  git push --set-upstream origin "${branch}"
)
