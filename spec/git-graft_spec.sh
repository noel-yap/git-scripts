#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-graft.sh'

  It 'fails when there are staged changes'
    set_up_and_call() {
      {
        init_repo
        echo change >> file
        git add file
      } >/dev/null 2>&1

      PATH="${PROJECT_ROOT_DIR}:${PATH}" \
        GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
        "${PROJECT_ROOT_DIR}/git-graft.sh" some-branch
    }

    When call in_tempdir set_up_and_call
    The status should be failure
    The stdout should not be blank
    The stderr should include 'ERROR: Uncommitted changes'
  End

  It 'prints grafting message with commit hashes'
    set_up_and_call() {
      {
        init_repo

        git branch feature
        git switch feature
        echo change > feature-file
        git add feature-file
        git commit -m 'feature commit'
        git switch main
      } >/dev/null 2>&1

      PATH="${PROJECT_ROOT_DIR}:${PATH}" \
        GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
        "${PROJECT_ROOT_DIR}/git-graft.sh" feature
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should start with 'grafting '
    The stderr should not be blank
  End

  It 'grafts a branch onto the current branch by branch name'
    set_up_and_call() {
      {
        init_repo

        git branch feature
        git switch feature
        echo change > feature-file
        git add feature-file
        git commit -m 'feature commit'

        git switch main
        echo main-change > main-file
        git add main-file
        git commit -m 'main commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          "${PROJECT_ROOT_DIR}/git-graft.sh" feature
      } >/dev/null 2>&1

      git log --oneline feature
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'feature commit'
    The stdout should include 'main commit'
    The stdout should include 'initial'
  End

  It 'grafts a commit range using the range syntax'
    set_up_and_call() {
      {
        init_repo

        git branch feature
        git switch feature
        echo change > feature-file
        git add feature-file
        git commit -m 'feature commit'

        git switch main
        echo main-change > main-file
        git add main-file
        git commit -m 'main commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          "${PROJECT_ROOT_DIR}/git-graft.sh" "feature~..feature"
      } >/dev/null 2>&1

      git log --oneline feature
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'feature commit'
    The stdout should include 'main commit'
    The stdout should include 'initial'
  End

End