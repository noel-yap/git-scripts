#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-ch-branch.sh'

  It 'switches to trunk (origin/HEAD) when no arguments are given'
    set_up_repo_and_workspace_then_call_git_ch_branch() {
      {
        git -c init.defaultBranch=some-trunk init
        touch file
        git add file
        git commit -m 'initial'
        git init --bare remote.git
        git remote add origin remote.git
        git push origin some-trunk
        git symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/some-trunk
        git switch -c branch-0
      } >/dev/null 2>&1

      "${PROJECT_ROOT_DIR}/git-ch-branch.sh"
    }

    When call in_tempdir set_up_repo_and_workspace_then_call_git_ch_branch

    The status should be success
    The stdout should be blank
    The stderr should equal "Switched to branch 'some-trunk'"
  End

  It 'switches to the provided branch name when an argument is given'
    set_up_repo_and_workspace_then_call_git_ch_branch() {
      {
        init_repo
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
        init_repo
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
