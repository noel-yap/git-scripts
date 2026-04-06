#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-create-task.sh'

  It 'uses $2 directly as project directory when not a git URL'
    set_up_and_call() {
      mock_first_with_rest acli 'echo "{}"'
      mock_first_with_rest jq 'echo "Do stuff"'
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
      mock_first_with_rest jq 'echo "Do stuff"'
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
      mock_first_with_rest jq 'echo "Do stuff"'
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

End
