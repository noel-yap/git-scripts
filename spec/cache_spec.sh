#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../cache.shlib
. "${PROJECT_ROOT_DIR}/cache.shlib"

Describe 'cache.shlib'

  Describe 'get_cache_dir'

    It 'returns cache.dir from git config when set'
      set_up_and_call() {
        {
          init_repo
          set_cache_dir /some/cache/dir
        } >/dev/null 2>&1

        get_cache_dir
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal '/some/cache/dir'
    End

    It 'falls back to the fetch remote URL when cache.dir is not set'
      set_up_and_call() {
        {
          init_repo
          init_remote
        } >/dev/null 2>&1

        get_cache_dir
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal 'remote.git'
    End

  End

  Describe 'set_cache_dir'

    It 'sets cache.dir in git config'
      set_up_and_call() {
        {
          init_repo
          set_cache_dir /some/cache/dir
        } >/dev/null 2>&1

        get_cache_dir
      }

      When call in_tempdir set_up_and_call
      The status should be success
      The stdout should equal '/some/cache/dir'
    End

  End

End