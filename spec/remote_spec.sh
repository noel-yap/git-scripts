#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../remote.shlib
. "${PROJECT_ROOT_DIR}/remote.shlib"

Describe 'remote.shlib'

  Describe 'get_remote'

    It 'returns origin when no upstream remote is configured'
      set_up_and_call() {
        {
          init_repo
          init_remote
        } >/dev/null 2>&1

        get_remote
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'origin'
    End

    It 'returns upstream when an upstream remote is configured'
      set_up_and_call() {
        {
          init_repo
          init_remote
          git init --bare upstream.git
          git remote add upstream upstream.git
        } >/dev/null 2>&1

        get_remote
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'upstream'
    End

  End

End