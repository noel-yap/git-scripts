#!/bin/sh

eval "$(shellspec - -c) exit 1"

# shellcheck source=../share-claude-memory.shlib
. "${PROJECT_ROOT_DIR}/share-claude-memory.shlib"

Describe 'share-claude-memory.shlib'

  Describe 'get_shared_claude_memory_dir'

    It 'creates shared memory directory and stub MEMORY.md'
      test_get_shared_claude_memory_dir() {
        local cache_dir="$PWD/cache"
        local result
        result="$(get_shared_claude_memory_dir "${cache_dir}")"

        # Verify the returned path is correct
        [ "${result}" = "${cache_dir}.claude-memory" ] || exit 1

        # Verify the directory was created
        [ -d "${result}" ] || exit 1

        # Verify MEMORY.md was created with expected content
        [ -f "${result}/MEMORY.md" ] || exit 1
        grep -q '^# Memory index$' "${result}/MEMORY.md" || exit 1
      }

      When call in_tempdir test_get_shared_claude_memory_dir
      The status should be success
    End

    It 'does not overwrite existing MEMORY.md with custom content'
      test_get_shared_claude_memory_dir_preserve() {
        local cache_dir="$PWD/cache"

        # First call creates the directory and stub
        get_shared_claude_memory_dir "${cache_dir}" > /dev/null

        # Add custom content to MEMORY.md
        printf '%s\n' '# Memory index' '' '- [custom-entry](custom-file.md)' >> "${cache_dir}.claude-memory/MEMORY.md"

        # Second call should not overwrite
        get_shared_claude_memory_dir "${cache_dir}" > /dev/null

        # Verify custom content is preserved
        grep -q 'custom-entry' "${cache_dir}.claude-memory/MEMORY.md" || exit 1
      }

      When call in_tempdir test_get_shared_claude_memory_dir_preserve
      The status should be success
    End

  End

  Describe 'write_auto_memory_setting'

    It 'creates settings.local.json with autoMemoryDirectory when file does not exist'
      test_write_auto_memory_setting_new() {
        local project_dir="$PWD/project"
        local shared_memory_dir="$PWD/shared-memory"

        mkdir -p "${project_dir}"
        mkdir -p "${shared_memory_dir}"

        write_auto_memory_setting "${project_dir}" "${shared_memory_dir}"

        # Verify settings file was created
        [ -f "${project_dir}/.claude/settings.local.json" ] || exit 1

        # Verify it contains the autoMemoryDirectory setting
        grep -q "autoMemoryDirectory" "${project_dir}/.claude/settings.local.json" || exit 1
        grep -q "${shared_memory_dir}" "${project_dir}/.claude/settings.local.json" || exit 1
      }

      When call in_tempdir test_write_auto_memory_setting_new
      The status should be success
    End

    It 'merges autoMemoryDirectory into existing settings.local.json while preserving other keys'
      test_write_auto_memory_setting_merge() {
        local project_dir="$PWD/project"
        local shared_memory_dir="$PWD/shared-memory"

        mkdir -p "${project_dir}/.claude"
        mkdir -p "${shared_memory_dir}"

        # Create existing settings file with other keys
        printf '%s\n' '{"someOtherKey": "value"}' > "${project_dir}/.claude/settings.local.json"

        write_auto_memory_setting "${project_dir}" "${shared_memory_dir}"

        # Verify both keys exist
        grep -q "someOtherKey" "${project_dir}/.claude/settings.local.json" || exit 1
        grep -q "autoMemoryDirectory" "${project_dir}/.claude/settings.local.json" || exit 1
        grep -q "${shared_memory_dir}" "${project_dir}/.claude/settings.local.json" || exit 1
      }

      When call in_tempdir test_write_auto_memory_setting_merge
      The status should be success
    End

    It 'overwrites existing autoMemoryDirectory with new value'
      test_write_auto_memory_setting_overwrite() {
        local project_dir="$PWD/project"
        local old_dir="$PWD/old-memory"
        local new_dir="$PWD/new-memory"

        mkdir -p "${project_dir}/.claude"
        mkdir -p "${old_dir}"
        mkdir -p "${new_dir}"

        # Create existing settings file with autoMemoryDirectory
        printf '%s\n' "{\"autoMemoryDirectory\": \"${old_dir}\"}" > "${project_dir}/.claude/settings.local.json"

        write_auto_memory_setting "${project_dir}" "${new_dir}"

        # Verify new directory is set
        if ! grep -q "${new_dir}" "${project_dir}/.claude/settings.local.json"; then
          exit 1
        fi
        # Verify old directory is NOT present
        if grep -q "${old_dir}" "${project_dir}/.claude/settings.local.json"; then
          exit 1
        fi
      }

      When call in_tempdir test_write_auto_memory_setting_overwrite
      The status should be success
    End

  End

  Describe 'ignore_claude_local_settings'

    It 'returns success and makes file ignored by git'
      test_ignore_claude_local_settings_basic() {
        local project_dir="$PWD/project"

        mkdir -p "${project_dir}"
        cd "${project_dir}"
        git init > /dev/null 2>&1

        # Isolate from the real user's global/system git config, including
        # the $XDG_CONFIG_HOME/git/ignore fallback (see the sibling test
        # below for why).
        export GIT_CONFIG_GLOBAL=/dev/null
        export GIT_CONFIG_NOSYSTEM=1
        export XDG_CONFIG_HOME="$PWD/xdg-config-empty"
        mkdir -p "${XDG_CONFIG_HOME}"

        # Call the function
        ignore_claude_local_settings "${project_dir}"

        # Verify git check-ignore returns success (file is ignored)
        if ! git check-ignore -q .claude/settings.local.json; then
          exit 1
        fi
      }

      When call in_tempdir test_ignore_claude_local_settings_basic
      The status should be success
    End

    It 'adds pattern to .git/info/exclude if not already globally ignored'
      test_ignore_claude_local_settings_adds_to_exclude() {
        local project_dir="$PWD/project"

        mkdir -p "${project_dir}"
        cd "${project_dir}"
        git init > /dev/null 2>&1

        # Isolate from the real user's global/system git config so this test
        # is hermetic and never touches (or depends on) ~/.gitconfig or
        # ~/.gitignore-global. GIT_CONFIG_GLOBAL/GIT_CONFIG_NOSYSTEM disable
        # the configured excludesfile, but git then falls back to
        # $XDG_CONFIG_HOME/git/ignore — override that too, to an empty
        # directory, so no pre-existing global ignore rule (this user's
        # real ~/.config/git/ignore already lists this exact pattern) can
        # make the file look "already ignored" before info/exclude is
        # written. These are read by every git invocation that follows,
        # including the ones inside ignore_claude_local_settings.
        export GIT_CONFIG_GLOBAL=/dev/null
        export GIT_CONFIG_NOSYSTEM=1
        export XDG_CONFIG_HOME="$PWD/xdg-config-empty"
        mkdir -p "${XDG_CONFIG_HOME}"

        ignore_claude_local_settings "${project_dir}"

        grep -q '\.claude/settings\.local\.json' \
          "${project_dir}/.git/info/exclude" || exit 1
      }

      When call in_tempdir test_ignore_claude_local_settings_adds_to_exclude
      The status should be success
    End

  End

End
