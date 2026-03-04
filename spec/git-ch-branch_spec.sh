#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-ch-branch.sh'

  It 'switches to init.defaultBranch when no arguments are given'
    set_up_repo_and_workspace_then_call_git_ch_branch() {
      {
        git init
        touch file
        git add file
        git commit -m 'message'

        git switch -c branch-0
      } >/dev/null 2>&1

      "${PROJECT_ROOT_DIR}/git-ch-branch.sh"
    }

    When call in_tempdir set_up_repo_and_workspace_then_call_git_ch_branch

    The status should be success
    The stdout should be blank
    The stderr should equal "Switched to branch 'main'"
  End

  It 'switches to the provided branch name when an argument is given'
    set_up_repo_and_workspace_then_call_git_ch_branch() {
      {
        git init
        touch file
        git add file
        git commit -m 'message'

        git branch branch-0
      } >/dev/null 2>&1

      "${PROJECT_ROOT_DIR}/git-ch-branch.sh" branch-0
    }

    When call in_tempdir set_up_repo_and_workspace_then_call_git_ch_branch

    The status should be success
    The stdout should be blank
    The stderr should equal "Switched to branch 'branch-0'"
  End

  It "treats '-' as the previous branch (@{-1})"
    set_up_repo_and_workspace_then_call_git_ch_branch() {
      {
        git init
        touch file
        git add file
        git commit -m 'message'

        git switch -c branch-1
        git switch -c branch-0
      } >/dev/null 2>&1

      "${PROJECT_ROOT_DIR}/git-ch-branch.sh" -
    }

    When call in_tempdir set_up_repo_and_workspace_then_call_git_ch_branch

    The status should be success
    The stdout should be blank
    The stderr should equal "Switched to branch 'branch-1'"
  End
End
