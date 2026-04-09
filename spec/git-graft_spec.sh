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

  It 'fails when branch has no union config'
    set_up_and_call() {
      {
        init_repo
        git branch feature
      } >/dev/null 2>&1

      PATH="${PROJECT_ROOT_DIR}:${PATH}" \
        GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
        "${PROJECT_ROOT_DIR}/git-graft.sh" feature
    }

    When call in_tempdir set_up_and_call
    The status should be failure
    The stderr should include 'ERROR: No union found'
  End

  It 'fails with an error when called directly with no args and there are no child branches'
    set_up_and_call() {
      {
        init_repo
      } >/dev/null 2>&1

      PATH="${PROJECT_ROOT_DIR}:${PATH}" \
        GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
        "${PROJECT_ROOT_DIR}/git-graft.sh"
    }

    When call in_tempdir set_up_and_call
    The status should be failure
    The stderr should include 'ERROR: No child branches found'
  End

  It 'warns when called recursively and a branch has no child branches'
    set_up_and_call() {
      {
        init_repo

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature
        echo change > feature-file
        git add feature-file
        git commit -m 'feature commit'

        git switch main
        echo main-change > main-file
        git add main-file
        git commit -m 'main commit'
      } >/dev/null 2>&1

      PATH="${PROJECT_ROOT_DIR}:${PATH}" \
        GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
        "${PROJECT_ROOT_DIR}/git-graft.sh" feature 2>&1
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'WARNING: No child branches found'
  End

  It 'grafts a branch onto the current branch by branch name'
    set_up_and_call() {
      {
        init_repo

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature
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

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature
        echo change1 > feature-file1
        git add feature-file1
        git commit -m 'feature commit 1'
        echo change2 > feature-file2
        git add feature-file2
        git commit -m 'feature commit 2'

        git switch main
        echo main-change > main-file
        git add main-file
        git commit -m 'main commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          "${PROJECT_ROOT_DIR}/git-graft.sh" "feature~2..feature"
      } >/dev/null 2>&1

      git log --oneline main
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'feature commit 1'
    The stdout should include 'feature commit 2'
    The stdout should include 'main commit'
    The stdout should include 'initial'
  End

  It 'recursively grafts child branch two levels deep'
    set_up_and_call() {
      {
        init_repo

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature
        echo feature-change > feature-file
        git add feature-file
        git commit -m 'feature commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud subfeature
        echo subfeature-change > subfeature-file
        git add subfeature-file
        git commit -m 'subfeature commit'

        git switch main
        echo main-change > main-file
        git add main-file
        git commit -m 'main commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          "${PROJECT_ROOT_DIR}/git-graft.sh" feature
      } >/dev/null 2>&1

      git log --oneline subfeature
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'subfeature commit'
    The stdout should include 'feature commit'
    The stdout should include 'main commit'
    The stdout should include 'initial'
  End

  It 'grafts a branch with multiple commits onto the current branch'
    set_up_and_call() {
      {
        init_repo

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature
        echo change1 > feature-file1
        git add feature-file1
        git commit -m 'feature commit 1'
        echo change2 > feature-file2
        git add feature-file2
        git commit -m 'feature commit 2'

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
    The stdout should include 'feature commit 1'
    The stdout should include 'feature commit 2'
    The stdout should include 'main commit'
    The stdout should include 'initial'
  End

  It 'grafts feature-2.1 onto feature-1 without including feature-2 changes'
    set_up_and_call() {
      {
        init_repo

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature-1
        echo feature-1-change > feature-1-file
        git add feature-1-file
        git commit -m 'feature-1 commit'

        git switch main
        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature-2
        echo feature-2-change > feature-2-file
        git add feature-2-file
        git commit -m 'feature-2 commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature-2.1
        echo feature-2.1-change > feature-2.1-file
        git add feature-2.1-file
        git commit -m 'feature-2.1 commit'

        git switch feature-1
        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          "${PROJECT_ROOT_DIR}/git-graft.sh" feature-2.1
      } >/dev/null 2>&1

      git log --oneline feature-2.1
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'feature-2.1 commit'
    The stdout should include 'feature-1 commit'
    The stdout should include 'initial'
    The stdout should not include 'feature-2 commit'
  End

  It 'grafts feature-2.1 onto feature-1 without including feature-2.1.1 changes'
    set_up_and_call() {
      {
        init_repo

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature-1
        echo feature-1-change > feature-1-file
        git add feature-1-file
        git commit -m 'feature-1 commit'

        git switch main
        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature-2
        echo feature-2-change > feature-2-file
        git add feature-2-file
        git commit -m 'feature-2 commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature-2.1
        echo feature-2.1-change > feature-2.1-file
        git add feature-2.1-file
        git commit -m 'feature-2.1 commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature-2.1.1
        echo feature-2.1.1-change > feature-2.1.1-file
        git add feature-2.1.1-file
        git commit -m 'feature-2.1.1 commit'

        git switch feature-1
        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          "${PROJECT_ROOT_DIR}/git-graft.sh" feature-2.1
      } >/dev/null 2>&1

      git log --oneline feature-2.1
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'feature-2.1 commit'
    The stdout should include 'feature-1 commit'
    The stdout should include 'initial'
    The stdout should not include 'feature-2.1.1 commit'
  End

  It 'grafts all child branches when a parent has two children'
    set_up_and_call() {
      {
        init_repo

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature1
        echo feature1-change > feature1-file
        git add feature1-file
        git commit -m 'feature1 commit'

        git switch main
        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          git bud feature2
        echo feature2-change > feature2-file
        git add feature2-file
        git commit -m 'feature2 commit'

        git switch main
        echo main-change > main-file
        git add main-file
        git commit -m 'main commit'

        PATH="${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          "${PROJECT_ROOT_DIR}/git-graft.sh"
      } >/dev/null 2>&1

      git log --oneline feature1
      git log --oneline feature2
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'feature1 commit'
    The stdout should include 'feature2 commit'
    The stdout should include 'main commit'
    The stdout should include 'initial'
  End

End