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

Describe 'get_task_slug'

  It 'returns task key unchanged when no ATLASSIAN_API_TOKEN and key is short'
    set_up_and_call() {
      unset ATLASSIAN_API_TOKEN
      get_task_slug 'do-something'
    }
    When call set_up_and_call
    The status should be success
    The stdout should equal 'do-something'
    The stderr should be blank
  End

  It 'truncates task key when no ATLASSIAN_API_TOKEN and key is 64+ characters'
    set_up_and_call() {
      unset ATLASSIAN_API_TOKEN
      get_task_slug 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    }
    When call set_up_and_call
    The status should be success
    The stdout should equal 'xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx⋯'
    The stderr should be blank
  End

  It 'returns task：summary when ATLASSIAN_API_TOKEN is set and result is short'
    set_up_and_call() {
      export ATLASSIAN_API_TOKEN=test
      mock_first_with_rest acli 'echo "{}"'
      mock_first_with_rest jq 'cat > /dev/null; echo "Dostuff"'
      get_task_slug 'ABC-123'
    }
    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should equal 'ABC-123：Dostuff'
    The stderr should be blank
  End

  It 'truncates task：summary when ATLASSIAN_API_TOKEN is set and result is 64+ characters'
    set_up_and_call() {
      export ATLASSIAN_API_TOKEN=test
      mock_first_with_rest acli 'echo "{}"'
      # 57 a's: ABC-123 (7) + ： (1) + 57 = 65 chars total
      mock_first_with_rest jq 'cat > /dev/null; echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"'
      get_task_slug 'ABC-123'
    }
    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should equal 'ABC-123：aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa⋯'
    The stderr should be blank
  End

End