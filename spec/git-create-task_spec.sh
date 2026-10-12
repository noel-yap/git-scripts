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

  It 'creates a tmp directory and an .envrc exporting TMPDIR in the task directory'
    set_up_and_call() {
      unset ATLASSIAN_API_TOKEN
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123 my-repo >/dev/null 2>&1
      test -d ABC-123/tmp && cat ABC-123/.envrc
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should equal 'export TMPDIR="${PWD}/tmp"'
  End

  It 'does not overwrite an existing .envrc'
    set_up_and_call() {
      unset ATLASSIAN_API_TOKEN
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'
      mkdir ABC-123
      echo 'existing' > ABC-123/.envrc

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123 my-repo >/dev/null 2>&1
      cat ABC-123/.envrc
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should equal 'existing'
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
      export ATLASSIAN_API_TOKEN=test LINEAR_API_KEY=test
      # set_key probes the Keychain first; report the item as absent (exit 44)
      # so it falls back to the exported env value without real Keychain access.
      printf '%s\n' '#!/bin/sh' 'exit 44' > security
      chmod +x security
      # get_task_slug makes one Linear call for branchName and title: jq builds
      # the payload, curl returns the GraphQL response, then jq parses it into
      # two lines (an empty branchName, then the title).
      mock_first_with_rest curl 'echo "{}"'
      mock_first_with_rest jq \
        'echo "{}"' \
        'cat > /dev/null; printf "\nDo stuff\n"'
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
    The stdout should end with '/my-repo'
    The stderr should include 'cwc git@github.com:org/my-repo.git'
  End

  It 'processes each argument after the task as its own project'
    set_up_and_call() {
      export ATLASSIAN_API_TOKEN=test LINEAR_API_KEY=test
      # set_key probes the Keychain first; report the item as absent (exit 44)
      # so it falls back to the exported env value without real Keychain access.
      printf '%s\n' '#!/bin/sh' 'exit 44' > security
      chmod +x security
      # This test asserts the bare ABC-123 slug, so every lookup must yield
      # nothing: stub curl (Linear) and acli (Jira) to fail.
      mock_first_with_rest curl 'exit 1'
      mock_first_with_rest acli 'exit 1'
      # CWD-independent mock: creates the project dir named after the cwc argument.
      printf '%s\n' '#!/bin/sh' 'case "$1" in cwc) mkdir -p "$2" ;; esac' > git
      chmod +x git

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123 my-repo other-repo
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The line 1 of stdout should equal 'ABC-123/my-repo'
    The line 2 of stdout should equal 'ABC-123/other-repo'
  End

  It 'extracts task key from https Jira browse URL'
    set_up_and_call() {
      export ATLASSIAN_API_TOKEN=test LINEAR_API_KEY=test
      # set_key probes the Keychain first; report the item as absent (exit 44)
      # so it falls back to the exported env value without real Keychain access.
      printf '%s\n' '#!/bin/sh' 'exit 44' > security
      chmod +x security
      # get_task_slug makes one Linear call for branchName and title: jq builds
      # the payload, curl returns the GraphQL response, then jq parses it into
      # two lines (an empty branchName, then the title).
      mock_first_with_rest curl 'echo "{}"'
      mock_first_with_rest jq \
        'echo "{}"' \
        'cat > /dev/null; printf "\nDo stuff\n"'
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
      export ATLASSIAN_API_TOKEN=test LINEAR_API_KEY=test
      # set_key probes the Keychain first; report the item as absent (exit 44)
      # so it falls back to the exported env value without real Keychain access.
      printf '%s\n' '#!/bin/sh' 'exit 44' > security
      chmod +x security
      # get_task_slug makes one Linear call for branchName and title: jq builds
      # the payload, curl returns the GraphQL response, then jq parses it into
      # two lines (an empty branchName, then the title).
      mock_first_with_rest curl 'echo "{}"'
      mock_first_with_rest jq \
        'echo "{}"' \
        'cat > /dev/null; printf "\nDo stuff\n"'
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
      export ATLASSIAN_API_TOKEN=test LINEAR_API_KEY=test
      # set_key probes the Keychain first; report the item as absent (exit 44)
      # so it falls back to the exported env value without real Keychain access.
      printf '%s\n' '#!/bin/sh' 'exit 44' > security
      chmod +x security
      # get_task_slug makes one Linear call for branchName and title: jq builds
      # the payload, curl returns the GraphQL response, then jq parses it into
      # two lines (an empty branchName, then the title).
      mock_first_with_rest curl 'echo "{}"'
      mock_first_with_rest jq \
        'echo "{}"' \
        'cat > /dev/null; printf "\nDo stuff\n"'
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

  It 'derives the project from the Linear "Repositories" label when no PROJECT_DIR_NAME is given'
    set_up_and_call() {
      export ATLASSIAN_API_TOKEN=test LINEAR_API_KEY=test
      # set_key probes the Keychain first; report the item as absent (exit 44)
      # so it falls back to the exported env value without real Keychain access.
      printf '%s\n' '#!/bin/sh' 'exit 44' > security
      chmod +x security
      # get_task_slug's branchName/title lookup and git-create-task.sh's
      # project-label fallback each build a GraphQL payload with jq, POST it
      # with curl, then parse the response with jq -- in that order, twice
      # over: slug (empty branchName, then title), then label.
      mock_first_with_rest curl 'echo "{}"' 'echo "{}"'
      mock_first_with_rest jq \
        'echo "{}"' \
        'cat > /dev/null; printf "\nDo stuff\n"' \
        'echo "{}"' \
        'cat > /dev/null; echo "my-repo"'
      mock_first_with_rest git \
        'mkdir -p my-repo' \
        'true' \
        'true' \
        'true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should end with '/my-repo'
    The stderr should not be blank
  End

  It 'fails when no PROJECT_DIR_NAME is given and the Linear issue has no "Repositories" label'
    set_up_and_call() {
      export ATLASSIAN_API_TOKEN=test LINEAR_API_KEY=test
      # set_key probes the Keychain first; report the item as absent (exit 44)
      # so it falls back to the exported env value without real Keychain access.
      printf '%s\n' '#!/bin/sh' 'exit 44' > security
      chmod +x security
      # Same call shape as above, but the label-parse jq call emits nothing --
      # an issue with no "Repositories" label.
      mock_first_with_rest curl 'echo "{}"' 'echo "{}"'
      mock_first_with_rest jq \
        'echo "{}"' \
        'cat > /dev/null; printf "\nDo stuff\n"' \
        'echo "{}"' \
        'cat > /dev/null; true'

      PATH="${PWD}:${PROJECT_ROOT_DIR}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-create-task.sh" ABC-123
    }

    When call in_tempdir set_up_and_call
    The status should be failure
    The stderr should include "No PROJECT_DIR_NAME given"
  End

  It 'uses the Linear branchName, with "/" unicodified, as the task slug'
    set_up_and_call() {
      export ATLASSIAN_API_TOKEN=test LINEAR_API_KEY=test
      # set_key probes the Keychain first; report the item as absent (exit 44)
      # so it falls back to the exported env value without real Keychain access.
      printf '%s\n' '#!/bin/sh' 'exit 44' > security
      chmod +x security
      # get_task_slug's single Linear lookup builds a payload with jq, POSTs it
      # with curl, then parses the response with jq into the branchName line
      # followed by an (empty) title line.
      mock_first_with_rest curl 'echo "{}"'
      mock_first_with_rest jq \
        'echo "{}"' \
        'cat > /dev/null; printf "noel/abc-123-fix-thing\n\n"'
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
    The stdout should equal 'noel⁄abc-123-fix-thing/my-repo'
    The stderr should not be blank
  End

End
