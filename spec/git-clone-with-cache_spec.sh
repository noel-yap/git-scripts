#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../git-clone-with-cache.shlib
. "${PROJECT_ROOT_DIR}/git-clone-with-cache.shlib"

Describe 'git-clone-with-cache.shlib'

  Describe 'get_repo_coordinates'

    It 'extracts domain, org, and project from a git SSH URL'
      When call get_repo_coordinates 'git@github.com:noel-yap/my-repo.git'
      The status should be success
      The stdout should include 'git_domain=github.com'
      The stdout should include 'git_org=noel-yap'
      The stdout should include 'project=my-repo'
    End

    It 'uses GIT_DOMAIN and GIT_ORG for a plain project name'
      export GIT_DOMAIN=github.com
      export GIT_ORG=noel-yap
      When call get_repo_coordinates 'my-repo'
      The status should be success
      The stdout should include 'git_domain=github.com'
      The stdout should include 'git_org=noel-yap'
      The stdout should include 'project=my-repo'
    End

    It 'uses GIT_DOMAIN and GIT_ORG for a git@ URL without .git suffix'
      export GIT_DOMAIN=example.com
      export GIT_ORG=my-org
      When call get_repo_coordinates 'git@github.com:noel-yap/my-repo'
      The status should be success
      The stdout should include 'git_domain=example.com'
      The stdout should include 'git_org=my-org'
    End

    It 'extracts domain, org, and project from a PR URL'
      When call get_repo_coordinates 'https://github.com/rzsoftware/redzone-webapp/pull/3100'
      The status should be success
      The stdout should include 'git_domain=github.com'
      The stdout should include 'git_org=rzsoftware'
      The stdout should include 'project=redzone-webapp'
    End

    It 'uses GIT_DOMAIN and GIT_ORG for an HTTPS URL without a PR path'
      export GIT_DOMAIN=example.com
      export GIT_ORG=my-org
      When call get_repo_coordinates 'https://github.com/rzsoftware/redzone-webapp'
      The status should be success
      The stdout should include 'git_domain=example.com'
      The stdout should include 'git_org=my-org'
    End

  End

End

Describe 'git-clone-with-cache.sh'

  It 'clones using domain and org from a git SSH URL'
    set_up_and_call() {
      export HOME="$PWD/fakehome"
      mkdir -p "$HOME"

      MOCK_DIR="$(mktemp -d)"
      export PATH="${MOCK_DIR}:${PROJECT_ROOT_DIR}:${PATH}"

      cat > "${MOCK_DIR}/git" <<'EOF'
#!/bin/sh
echo "git $*"
case "$1" in
  clone-or-pull) mkdir -p "${2##*/}" ;;
  rev-parse) echo "origin/main" ;;
esac
EOF
      chmod +x "${MOCK_DIR}/git"

      "${PROJECT_ROOT_DIR}/git-clone-with-cache.sh" git@gitlab.com:other-org/other-repo.git 2>&1
    }

    When call in_tempdir set_up_and_call
    The status should be success
    The stdout should include '.cache/git/gitlab.com/other-org/other-repo'
    The stdout should include 'git clone-or-pull git@gitlab.com:other-org/other-repo.git'
  End

End
