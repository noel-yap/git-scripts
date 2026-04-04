#!/bin/sh

eval "$(shellspec - -c) exit 1"

Describe 'git-clone-with-cache.sh'

  It 'extracts project name when argument is a git SSH URL'
    set_up_and_call() {
      export GIT_DOMAIN=github.com
      export GIT_ORG=noel-yap
      export HOME="$PWD/fakehome"
      mkdir -p "$HOME"

      # Mock git
      mock_first_with_rest git \
        'echo origin/main' # for get_trunk (rev-parse)
      # Other git calls will be caught by bash-mock and it will echo them if not matched,
      # but bash-mock might fail if no more mocks are provided and it's called again.
      # Wait, mock_first_with_rest only mocks for the next call.
      # Actually, bash-mock's mock_first_with_rest allows multiple mocks.

      # git clone-or-pull (line 26)
      # git clone-or-pull (line 29)
      # git config cache.dir ... (line 33)
      # git remote set-url ... (line 34)
      # git remote add ... (line 35)
      # git fetch ... (line 36)

      # Wait, mock_first_with_rest might be tricky here because of many calls.
      # Let's just create a custom mock in PATH for simplicity.
      
      MOCK_DIR="$(mktemp -d)"
      export PATH="${MOCK_DIR}:${PROJECT_ROOT_DIR}:${PATH}"
      
      printf '#!/bin/sh\necho "git $*"\ncase "$1" in rev-parse) echo "origin/main" ;; esac\n' > "${MOCK_DIR}/git"
      chmod +x "${MOCK_DIR}/git"
      
      printf '#!/bin/sh\necho "mkdir $*"\n' > "${MOCK_DIR}/mkdir"
      chmod +x "${MOCK_DIR}/mkdir"

      "${PROJECT_ROOT_DIR}/git-clone-with-cache.sh" git@github.com:noel-yap/git-scripts.git 2>&1
    }

    When call in_tempdir set_up_and_call
    The status should be success
    # Check that it extracted 'git-scripts' and didn't use the whole URL
    # If it failed to extract, the output would include the full URL where only 'git-scripts' is expected.
    The stdout should include "git clone-or-pull git@github.com:noel-yap/git-scripts.git"
    The stdout should include ".cache/git/github.com/noel-yap/git-scripts"
    The stdout should not include ".cache/git/github.com/noel-yap/git@github.com"
  End

  It 'uses GIT_DOMAIN and GIT_ORG when argument is just a project name'
    set_up_and_call() {
      export GIT_DOMAIN=github.com
      export GIT_ORG=noel-yap
      export HOME="$PWD/fakehome"
      mkdir -p "$HOME"
      
      MOCK_DIR="$(mktemp -d)"
      export PATH="${MOCK_DIR}:${PROJECT_ROOT_DIR}:${PATH}"
      
      printf '#!/bin/sh\necho "git $*"\ncase "$1" in rev-parse) echo "origin/main" ;; esac\n' > "${MOCK_DIR}/git"
      chmod +x "${MOCK_DIR}/git"
      
      printf '#!/bin/sh\necho "mkdir $*"\n' > "${MOCK_DIR}/mkdir"
      chmod +x "${MOCK_DIR}/mkdir"

      "${PROJECT_ROOT_DIR}/git-clone-with-cache.sh" git-scripts 2>&1
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include "git clone-or-pull git@github.com:noel-yap/git-scripts.git"
    The stdout should include ".cache/git/github.com/noel-yap/git-scripts"
  End
  It 'extracts git_domain and git_org when argument is a git SSH URL'
    set_up_and_call() {
      export GIT_DOMAIN=github.com
      export GIT_ORG=noel-yap
      export HOME="$PWD/fakehome"
      mkdir -p "$HOME"
      
      MOCK_DIR="$(mktemp -d)"
      export PATH="${MOCK_DIR}:${PROJECT_ROOT_DIR}:${PATH}"
      
      printf '#!/bin/sh\necho "git $*"\ncase "$1" in rev-parse) echo "origin/main" ;; esac\n' > "${MOCK_DIR}/git"
      chmod +x "${MOCK_DIR}/git"
      
      printf '#!/bin/sh\necho "mkdir $*"\n' > "${MOCK_DIR}/mkdir"
      chmod +x "${MOCK_DIR}/mkdir"

      # URL points to gitlab.com/other-org
      "${PROJECT_ROOT_DIR}/git-clone-with-cache.sh" git@gitlab.com:other-org/other-repo.git 2>&1
    }

    When call in_tempdir set_up_and_call
    The status should be success
    # Check that it extracted 'gitlab.com' and 'other-org'
    The stdout should include ".cache/git/gitlab.com/other-org/other-repo"
    The stdout should not include ".cache/git/github.com/noel-yap/other-repo"
    The stdout should include "git clone-or-pull git@gitlab.com:other-org/other-repo.git"
  End
End
