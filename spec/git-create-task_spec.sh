#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-create-task.sh'

  It 'restores directory permissions on exit'
    set_up_and_call() {
      unset ATLASSIAN_API_TOKEN
      local tmpdir
      tmpdir="$(mktemp -d)"
      (
        cd "${tmpdir}"
        mock_first_with_rest git \
          'mkdir -p my-repo' \
          'true' \
          'true' \
          'true'
      )
      chmod 555 "${tmpdir}"
      (
        cd "${tmpdir}"
        PATH="${tmpdir}:${PROJECT_ROOT_DIR}:${PATH}" \
          "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123 my-repo
      )
      echo "permissions:$(stat -f %Lp "${tmpdir}")"
      chmod 700 "${tmpdir}"
      rm -rf "${tmpdir}"
    }

    When call set_up_and_call
    The status should be success
    The stdout should include 'permissions:555'
    The stderr should not be blank
  End

  It 'outputs task_slug/project to stdout'
    set_up_and_call() {
      unset ATLASSIAN_API_TOKEN
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
    The stdout should end with 'ABC-123/my-repo'
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

End
