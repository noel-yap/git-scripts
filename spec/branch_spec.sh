#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../branch.shlib
. "${PROJECT_ROOT_DIR}/branch.shlib"

Describe 'branch.shlib'

  Describe 'get_parent_branch'

    It 'returns the parent of a branch'
      set_up_and_call() {
        {
          init_repo
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
        } >/dev/null 2>&1

        get_parent_branch feature
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'main'
    End

    It 'returns the parent of a branch with a dot in the name'
      set_up_and_call() {
        {
          init_repo
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud 'feat.ure'
        } >/dev/null 2>&1

        get_parent_branch 'feat.ure'
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'main'
    End

    It 'returns the parent of a nested branch'
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

        get_parent_branch subfeature
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'feature'
    End

  End

  Describe 'get_children_branches'

    It 'returns nothing when branch has no children'
      set_up_and_call() {
        {
          init_repo
        } >/dev/null 2>&1

        get_children_branches main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should be blank
    End

    It 'returns the single child of a branch'
      set_up_and_call() {
        {
          init_repo
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
        } >/dev/null 2>&1

        get_children_branches main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'feature'
    End

    It 'returns all children of a branch'
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

        get_children_branches main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should include 'feature1'
      The stdout should include 'feature2'
    End

    It 'returns a child branch with a dot in the name'
      set_up_and_call() {
        {
          init_repo
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud 'feat.ure'
        } >/dev/null 2>&1

        get_children_branches main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'feat.ure'
    End

    It 'does not return branches whose parent only prefix-matches'
      set_up_and_call() {
        {
          init_repo
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud feature
          git switch main
          git checkout -b main-extra
          PATH="${PROJECT_ROOT_DIR}:${PATH}" \
            GIT_CONFIG_GLOBAL="${PROJECT_ROOT_DIR}/.gitconfig" \
            git bud other
        } >/dev/null 2>&1

        get_children_branches main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'feature'
      The stdout should not include 'other'
    End

    It 'does not return grandchildren'
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

        get_children_branches main
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'feature'
      The stdout should not include 'subfeature'
    End

  End

End