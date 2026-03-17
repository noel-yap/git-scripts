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
      git config branch.new-branch.parent
    }

    When call in_tempdir set_up_repo_and_workspace_then_call_git_mk_branch

    The status should be success
    The line 1 should include 'new-branch'
    The line 2 should equal 'main'
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

  It 'creates a branch with the correct name when --parent option precedes the branch name'
    set_up_and_call() {
      {
        init_repo
        "${PROJECT_ROOT_DIR}/git-mk-branch.sh" --parent=parent-branch new-branch
      } >/dev/null 2>&1

      git branch --list new-branch
      git config branch.new-branch.parent
    }

    When call in_tempdir set_up_and_call

    The status should be success
    The line 1 should equal '  new-branch'
    The line 2 should equal 'parent-branch'
  End

  It 'sets branch.parent config to --parent option when provided before branch name'
    set_up_and_call() {
      {
        init_repo
        git bud other-branch
        "${PROJECT_ROOT_DIR}/git-mk-branch.sh" --parent=another-branch new-branch
      } >/dev/null 2>&1

      git config branch.new-branch.parent
    }

    When call in_tempdir set_up_and_call

    The status should be success
    The stdout should equal 'another-branch'
  End

  It 'sets branch.parent config to --parent option when provided after branch name'
    set_up_and_call() {
      {
        init_repo
        git bud other-branch
        "${PROJECT_ROOT_DIR}/git-mk-branch.sh" new-branch --parent=another-branch
      } >/dev/null 2>&1

      git config branch.new-branch.parent
    }

    When call in_tempdir set_up_and_call

    The status should be success
    The stdout should equal 'another-branch'
  End

  It 'sets branch.parent config to current branch when --parent is not provided'
    set_up_and_call() {
      {
        init_repo
        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud other-branch
        "${PROJECT_ROOT_DIR}/git-mk-branch.sh" new-branch
      } >/dev/null 2>&1

      git config branch.new-branch.parent
    }

    When call in_tempdir set_up_and_call

    The status should be success
    The stdout should equal 'other-branch'
  End

  It 'sets branch.parent config to trunk as resolved from origin/HEAD when --parent=TRUNK'
    set_up_and_call() {
      {
        init_repo
        init_remote
        git config init.defaultBranch other-branch
        "${PROJECT_ROOT_DIR}/git-mk-branch.sh" --parent=TRUNK new-branch
      } >/dev/null 2>&1

      git config branch.new-branch.parent
    }

    When call in_tempdir set_up_and_call

    The status should be success
    The stdout should equal 'main'
  End

  It 'fails with a message when parent is empty (detached HEAD)'
    set_up_and_call() {
      {
        init_repo
        git checkout --detach
      } >/dev/null 2>&1

      "${PROJECT_ROOT_DIR}/git-mk-branch.sh" new-branch
    }

    When call in_tempdir set_up_and_call

    The status should be failure
    The stderr should include 'parent must be set; use --parent'
  End

End