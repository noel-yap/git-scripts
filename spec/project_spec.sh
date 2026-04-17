#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../project.shlib
. "${PROJECT_ROOT_DIR}/project.shlib"

Describe 'project.shlib'

  Describe 'get_project'

    It 'returns plain name unchanged'
      When call get_project 'my-repo'
      The status should be success
      The stdout should equal 'my-repo'
    End

    It 'extracts repo name from git@ URL'
      When call get_project 'git@github.com:org/my-repo.git'
      The status should be success
      The stdout should equal 'my-repo'
    End

  End

End