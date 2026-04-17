#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../task.shlib
. "${PROJECT_ROOT_DIR}/task.shlib"

Describe 'task.shlib'

  Describe 'get_task'

    It 'extracts task key from selectedIssue query parameter'
      When call get_task 'https://jira.example.com/board?selectedIssue=ABC-123'
      The status should be success
      The stdout should equal 'ABC-123'
    End

    It 'extracts task key from /browse/ path segment'
      When call get_task 'https://jira.example.com/browse/ABC-123'
      The status should be success
      The stdout should equal 'ABC-123'
    End

    It 'returns plain task key unchanged'
      When call get_task 'ABC-123'
      The status should be success
      The stdout should equal 'ABC-123'
    End

    It 'selectedIssue takes precedence over /browse/ path segment'
      When call get_task 'https://jira.example.com/browse/WRONG-999?selectedIssue=ABC-123'
      The status should be success
      The stdout should equal 'ABC-123'
    End

  End

End