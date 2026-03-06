#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../git-edit-pr.shlib
. "${PROJECT_ROOT_DIR}/git-edit-pr.shlib"

Describe 'git-edit-pr.shlib'

  Describe 'edit_pr'

    It 'outputs URL from gh pr create when PR is created successfully'
      set_up_and_call() {
        {
          init_repo
          init_remote
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
        } >/dev/null 2>&1

        mock_first_with_rest gh \
          'echo https://feature-url'

        PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          edit_pr feature 2>/dev/null
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'https://feature-url'
    End

    It 'outputs URL from gh pr view when PR already exists'
      set_up_and_call() {
        {
          init_repo
          init_remote
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
        } >/dev/null 2>&1

        mock_first_with_rest gh \
          'exit 1' \
          'echo https://feature-url'

        PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
          GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
          edit_pr feature 2>/dev/null
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'https://feature-url'
    End

  End

  Describe 'edit_children_prs'

    It 'does not call edit_pr when branch has no children'
      set_up_and_call() {
        {
          init_repo
        } >/dev/null 2>&1

        edit_pr() {
          echo "edit_pr: $1"
        }

        edit_children_prs main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should be blank
    End

    It 'calls edit_pr for a single child branch'
      set_up_and_call() {
        {
          init_repo
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
        } >/dev/null 2>&1

        edit_pr() {
          echo "edit_pr: $1"
        }

        edit_children_prs main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'edit_pr: feature'
    End

    It 'calls edit_pr for each of two child branches'
      set_up_and_call() {
        {
          init_repo
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature1
          git switch main
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature2
        } >/dev/null 2>&1

        edit_pr() {
          echo "edit_pr: $1"
        }

        edit_children_prs main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should include 'edit_pr: feature1'
      The stdout should include 'edit_pr: feature2'
    End

    It 'recursively calls edit_pr for nested child branches'
      set_up_and_call() {
        {
          init_repo
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud subfeature
        } >/dev/null 2>&1

        edit_pr() {
          echo "edit_pr: $1"
        }

        edit_children_prs main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal "$(printf '%s\n%s' \
        'edit_pr: feature' \
        'edit_pr: subfeature')"
    End

  End

  Describe 'edit_parent_prs'

    It 'calls edit_pr once when parent is trunk'
      set_up_and_call() {
        {
          init_repo
          init_remote
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
        } >/dev/null 2>&1

        edit_pr() {
          echo "edit_pr: $1"
        }

        edit_parent_prs feature
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'edit_pr: feature'
    End

    It 'calls edit_pr for parent before branch when parent is not trunk'
      set_up_and_call() {
        {
          init_repo
          init_remote
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud subfeature
        } >/dev/null 2>&1

        edit_pr() {
          echo "edit_pr: $1"
        }

        edit_parent_prs subfeature
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should include 'edit_pr: feature'
      The stdout should include 'edit_pr: subfeature'
    End

    It 'calls edit_pr in order from root to branch for three levels'
      set_up_and_call() {
        {
          init_repo
          init_remote
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud subfeature
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud subsubfeature
        } >/dev/null 2>&1

        edit_pr() {
          echo "edit_pr: $1"
        }

        edit_parent_prs subsubfeature
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal "$(printf '%s\n%s\n%s' \
        'edit_pr: feature' \
        'edit_pr: subfeature' \
        'edit_pr: subsubfeature')"
    End

  End

End

Describe 'git-edit-pr.sh'

  setup_repo() {
    init_repo
    init_remote

    PATH="${PROJECT_ROOT_DIR}:${PATH}" \
      GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
      git bud parent-branch
    PATH="${PROJECT_ROOT_DIR}:${PATH}" \
      GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
      git bud current-branch
    PATH="${PROJECT_ROOT_DIR}:${PATH}" \
      GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
      git bud child-branch
    git switch current-branch
  }

  It 'calls edit_parent_prs and edit_children_prs when both succeed'
    set_up_and_call() {
      {
        setup_repo

        mock_first_with_rest gh \
          'echo https://parent-url' \
          'echo https://current-url' \
          'echo https://child-url'
      } >/dev/null 2>&1

      Google_Chrome() {
        echo "$@"
      }
      # shellcheck disable=SC3045
      export -f Google_Chrome

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
        CHROME_PROFILE='Profile 1' \
        "${PROJECT_ROOT_DIR}/git-edit-pr.sh" 2>/dev/null
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'https://parent-url'
    The stdout should include 'https://child-url'
  End

  It 'calls edit_children_prs even when edit_parent_prs fails'
    set_up_and_call() {
      {
        setup_repo

        # gh pr create and gh pr view both fail for parent-branch,
        # so edit_pr parent-branch (and thus edit_parent_prs) fails.
        # edit_children_prs should still run and produce child-url.
        mock_first_with_rest gh \
          'exit 1' \
          'exit 1' \
          'echo https://child-url'
      } >/dev/null 2>&1

      Google_Chrome() {
        echo "$@"
      }
      # shellcheck disable=SC3045
      export -f Google_Chrome

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
        CHROME_PROFILE='Profile 1' \
        "${PROJECT_ROOT_DIR}/git-edit-pr.sh" 2>/dev/null
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'https://child-url'
  End

  It 'calls Google_Chrome even when edit_children_prs fails'
    set_up_and_call() {
      {
        setup_repo

        # edit_parent_prs succeeds for parent and current branches.
        # gh pr create and gh pr view both fail for child-branch,
        # so edit_children_prs fails.
        # Google_Chrome should still be called with the parent/current URLs.
        mock_first_with_rest gh \
          'echo https://parent-url' \
          'echo https://current-url' \
          'exit 1' \
          'exit 1'
      } >/dev/null 2>&1

      Google_Chrome() {
        echo "$@"
      }
      # shellcheck disable=SC3045
      export -f Google_Chrome

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
        CHROME_PROFILE='Profile 1' \
        "${PROJECT_ROOT_DIR}/git-edit-pr.sh" 2>/dev/null
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'https://parent-url'
    The stdout should include 'https://current-url'
  End

End