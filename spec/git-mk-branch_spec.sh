#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-mk-branch.sh'

  It 'initializes a git repo when not inside a work tree'
    call_git_mk_branch() {
      "${PROJECT_ROOT_DIR}/git-mk-branch.sh"
    }

    When call in_tempdir call_git_mk_branch

    The status should be success
    The stdout should include 'Initialized empty Git repository'
  End

  It 'creates a branch with the given name'
    set_up_repo_and_workspace_then_call_git_mk_branch() {
      {
        init_repo
        "${PROJECT_ROOT_DIR}/git-mk-branch.sh" new-branch
      } >/dev/null 2>&1

      git branch --list new-branch
    }

    When call in_tempdir set_up_repo_and_workspace_then_call_git_mk_branch

    The status should be success
    The stdout should include 'new-branch'
  End

  It 'sets branch.parent config to the current branch'
    set_up_repo_and_workspace_then_call_git_mk_branch() {
      {
        init_repo
        "${PROJECT_ROOT_DIR}/git-mk-branch.sh" new-branch
      } >/dev/null 2>&1

      git config branch.new-branch.parent
    }

    When call in_tempdir set_up_repo_and_workspace_then_call_git_mk_branch

    The status should be success
    The stdout should equal 'main'
  End

  It 'sets parent config to the current non-default branch'
    set_up_repo_and_workspace_then_call_git_mk_branch() {
      {
        init_repo
        git switch -c feature-branch
        "${PROJECT_ROOT_DIR}/git-mk-branch.sh" child-branch
      } >/dev/null 2>&1

      git config branch.child-branch.parent
    }

    When call in_tempdir set_up_repo_and_workspace_then_call_git_mk_branch

    The status should be success
    The stdout should equal 'feature-branch'
  End

End