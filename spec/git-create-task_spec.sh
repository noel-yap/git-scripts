#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-create-task.sh'

  It 'uses $2 directly as project directory when not a git URL'
    set_up_and_call() {
      mock_first_with_rest acli 'echo "{}"'
      mock_first_with_rest jq 'cat > /dev/null; echo "Do stuff"'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123 my-repo
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'my-repo'
    The stderr should not be blank
  End

  It 'extracts repo name from git@ URL as project directory'
    set_up_and_call() {
      mock_first_with_rest acli 'echo "{}"'
      mock_first_with_rest jq 'cat > /dev/null; echo "Do stuff"'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123 git@github.com:org/my-repo.git
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'my-repo'
    The stderr should not be blank
  End

  It 'passes the original $2 to git cwc when given a git@ URL'
    set_up_and_call() {
      mock_first_with_rest acli 'echo "{}"'
      mock_first_with_rest jq 'cat > /dev/null; echo "Do stuff"'
      mock_first_with_rest git \
        'mkdir -p my-repo; echo "git $*"' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123 git@github.com:org/my-repo.git
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'cwc git@github.com:org/my-repo.git'
    The stderr should not be blank
  End

  It 'extracts task key from https Jira browse URL'
    set_up_and_call() {
      mock_first_with_rest acli 'echo "{}"'
      mock_first_with_rest jq 'cat > /dev/null; echo "Do stuff"'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" 'https://jira.example.com/browse/ABC-123' my-repo
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'ABC-123'
    The stdout should not include 'https'
    The stderr should not be blank
  End

  It 'extracts task key from selectedIssue query parameter in https URL'
    set_up_and_call() {
      mock_first_with_rest acli 'echo "{}"'
      mock_first_with_rest jq 'cat > /dev/null; echo "Do stuff"'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" 'https://jira.example.com/board?selectedIssue=ABC-123' my-repo
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'ABC-123'
    The stdout should not include 'https'
    The stderr should not be blank
  End

  It 'selectedIssue query parameter takes precedence over /browse path'
    set_up_and_call() {
      mock_first_with_rest acli 'echo "{}"'
      mock_first_with_rest jq 'cat > /dev/null; echo "Do stuff"'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" 'https://jira.example.com/browse/WRONG-999?selectedIssue=ABC-123' my-repo
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'ABC-123'
    The stdout should not include 'WRONG-999'
    The stdout should not include 'https'
    The stderr should not be blank
  End

  It 'uses task key as branch name when ATLASSIAN_API_TOKEN is not set'
    set_up_and_call() {
      unset ATLASSIAN_API_TOKEN
      mock_first_with_rest acli 'echo "UNEXPECTED acli call" >&2; exit 1'
      mock_first_with_rest jq 'echo "UNEXPECTED jq call" >&2; exit 1'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" 'do-something' 'my-repo'
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'do-something'
    The stderr should not be blank
  End

  It 'omits ellipsis when task_and_summary is shorter than 64 characters'
    set_up_and_call() {
      unset ATLASSIAN_API_TOKEN
      mock_first_with_rest acli 'echo "UNEXPECTED acli call" >&2; exit 1'
      mock_first_with_rest jq 'echo "UNEXPECTED jq call" >&2; exit 1'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" 'do-something' 'my-repo'
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include 'do-something'
    The stdout should not include '⋯'
    The stderr should not be blank
  End

  It 'appends ellipsis when task_and_summary is 64 characters or longer'
    set_up_and_call() {
      export ATLASSIAN_API_TOKEN=test
      mock_first_with_rest acli 'echo "{}"'
      # 57 a's: ABC-123 (7) + ： (1) + 57 = 65 chars total
      mock_first_with_rest jq 'cat > /dev/null; echo "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" 'ABC-123' 'my-repo'
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include '⋯'
    The stderr should not be blank
  End

End
