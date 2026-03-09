#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-mcb.sh'

  It 'passes all args and options to git mb'
    set_up_and_call() {
      mock_first_with_rest git \
        'echo "git $*"' \
        'echo "git $*"'

      PATH="${PWD}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-mcb.sh" --parent=main new-branch
    }

    When call in_tempdir set_up_and_call

    The status should be success
    The stdout should include 'git mb --parent=main new-branch'
  End

  It 'passes only the branch name to git cb'
    set_up_and_call() {
      mock_first_with_rest git \
        'echo "git $*"' \
        'echo "git $*"'

      PATH="${PWD}:${PATH}" \
        "${PROJECT_ROOT_DIR}/git-mcb.sh" --parent=main new-branch
    }

    When call in_tempdir set_up_and_call

    The status should be success
    The stdout should include 'git cb new-branch'
    The stdout should not include 'git cb --parent'
  End

End