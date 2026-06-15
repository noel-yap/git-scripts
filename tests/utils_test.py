"""Tests for functions in utils.shlib.

Each function is invoked in a fresh `bash` subprocess that sources the library.
The shell runs under the same strict flags as the production hook
(`set -e -o pipefail -u; shopt -s inherit_errexit`) so tests catch bugs that
only manifest under those flags.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

import pytest

from test_utils import _run

SHLIB = Path(__file__).parent.parent / "utils.shlib"


class TestGetKeyFromEnv:
    def test_returns_empty_when_named_var_is_unset(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'unset DEFINITELY_NOT_SET_XYZ; '
            'get_key_from_env DEFINITELY_NOT_SET_XYZ'
        )
        assert result.returncode == 0
        assert result.stdout == "\n"
        assert result.stderr == ""

    def test_returns_value_when_named_var_is_set(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'export MY_VAR=present; '
            'get_key_from_env MY_VAR'
        )
        assert result.returncode == 0
        assert result.stdout == "present\n"


class TestProbeKeySource:
    """probe_key_source returns 127 when the binary is missing, 0 with the
    command's output on success, and the command's own exit status on failure.
    """

    def test_returns_127_when_binary_not_installed(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            '( PATH=""; rc=0; probe_key_source definitely-not-a-binary || rc=$?; '
            'printf "%s" "${rc}" )'
        )
        assert result.returncode == 0
        assert result.stdout == "127"

    def test_succeeds_and_emits_output_when_command_succeeds(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'mycmd() { printf "the-secret"; }; '
            'probe_key_source mycmd'
        )
        assert result.returncode == 0
        assert result.stdout == "the-secret"

    def test_propagates_command_status_and_output_when_command_fails(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'mycmd() { printf "boom"; return 3; }; '
            'rc=0; out="$(probe_key_source mycmd)" || rc=$?; '
            'printf "%s:%s" "${rc}" "${out}"'
        )
        assert result.returncode == 0
        assert result.stdout == "3:boom"


class TestCoalesce:
    def test_returns_nonzero_when_no_args_given(self) -> None:
        result = _run(f'source "{SHLIB}"; coalesce')
        assert result.returncode != 0
        assert result.stdout == ""

    def test_returns_nonzero_when_only_separator_and_args(self) -> None:
        result = _run(f'source "{SHLIB}"; coalesce -- arg1 arg2')
        assert result.returncode != 0
        assert result.stdout == ""

    def test_returns_output_of_sole_succeeding_function(self) -> None:
        result = _run(f'source "{SHLIB}"; say_hello() {{ printf "hello"; }}; coalesce say_hello')
        assert result.returncode == 0
        assert result.stdout == "hello"

    def test_returns_nonzero_when_sole_function_fails(self) -> None:
        result = _run(f'source "{SHLIB}"; fail() {{ return 1; }}; coalesce fail')
        assert result.returncode != 0
        assert result.stdout == ""

    def test_returns_nonzero_when_sole_function_outputs_nothing(self) -> None:
        result = _run(f'source "{SHLIB}"; silent() {{ :; }}; coalesce silent')
        assert result.returncode != 0
        assert result.stdout == ""

    def test_skips_failing_function_and_uses_next(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'fail() { return 1; }; '
            'say_hello() { printf "hello"; }; '
            'coalesce fail say_hello'
        )
        assert result.returncode == 0
        assert result.stdout == "hello"

    def test_skips_empty_output_function_and_uses_next(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'silent() { :; }; '
            'say_hello() { printf "hello"; }; '
            'coalesce silent say_hello'
        )
        assert result.returncode == 0
        assert result.stdout == "hello"

    def test_stops_at_first_successful_function(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'say_hello() { printf "hello"; }; '
            'say_world() { printf "world"; }; '
            'coalesce say_hello say_world'
        )
        assert result.returncode == 0
        assert result.stdout == "hello"

    def test_passes_args_after_separator_to_function(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'join() { printf "%s-%s" "$1" "$2"; }; '
            'coalesce join -- hello world'
        )
        assert result.returncode == 0
        assert result.stdout == "hello-world"

    def test_passes_args_to_subsequent_function_after_skipping(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'fail() { return 1; }; '
            'echo_arg() { printf "got-%s" "$1"; }; '
            'coalesce fail echo_arg -- LINEAR_API_KEY'
        )
        assert result.returncode == 0
        assert result.stdout == "got-LINEAR_API_KEY"


class TestCoalesceSeverity:
    """coalesce returns the most severe (highest) exit status when none succeed."""

    def test_returns_1_when_all_absent(self) -> None:
        result = _run(f'source "{SHLIB}"; a() {{ return 1; }}; b() {{ return 1; }}; coalesce a b')
        assert result.returncode == 1

    def test_returns_2_when_any_errored(self) -> None:
        result = _run(f'source "{SHLIB}"; a() {{ return 1; }}; b() {{ return 2; }}; coalesce a b')
        assert result.returncode == 2

    def test_keeps_highest_status_regardless_of_order(self) -> None:
        result = _run(f'source "{SHLIB}"; a() {{ return 2; }}; b() {{ return 1; }}; coalesce a b')
        assert result.returncode == 2

    def test_success_short_circuits_before_an_errored_source(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'a() { printf "hit"; }; b() { return 2; }; coalesce a b'
        )
        assert result.returncode == 0
        assert result.stdout == "hit"


_STUBS = (
    'get_key_from_mac() { return 1; }; '
    'get_key_from_1password() { return 1; }; '
    'get_key_from_aws() { return 1; }; '
    'put_key_in_mac() { :; }; '
    'expire_key_in_mac() { :; }; '
)


# 1Password and AWS both reach set_key through fetch_and_cache_key_in_mac: each
# fetches from its source, caches the hit in the Keychain, then emits it. These
# cases pin that shared behavior down for every fetched source.
_FETCHED_SOURCES = (
    pytest.param('get_key_from_1password() { printf "op-value"; }; ', "op-value", id="1password"),
    pytest.param('get_key_from_aws() { printf "aws-value"; }; ', "aws-value", id="aws"),
)


class TestFetchAndCacheKeyInMac:
    """fetch_and_cache_key_in_mac caches a successfully fetched value in the
    Keychain, and otherwise propagates the fetcher's exit code without caching.
    """

    def test_emits_value_and_succeeds_when_fetcher_succeeds(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'put_key_in_mac() { :; }; '
            'fetcher() { printf "secret"; }; '
            'fetch_and_cache_key_in_mac MY_VAR fetcher'
        )
        assert result.returncode == 0
        assert result.stdout == "secret"

    def test_caches_value_under_key_name_when_fetcher_succeeds(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'CALLS=$(mktemp); trap \'rm -f "${CALLS}"\' EXIT; '
            'put_key_in_mac() { printf "%s %s" "$1" "$2" >> "${CALLS}"; }; '
            'fetcher() { printf "secret"; }; '
            'fetch_and_cache_key_in_mac MY_VAR fetcher >/dev/null; '
            'cat "${CALLS}"'
        )
        assert result.returncode == 0
        assert result.stdout == "MY_VAR secret"

    def test_passes_extra_arguments_through_to_fetcher(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'put_key_in_mac() { :; }; '
            'fetcher() { printf "%s" "$*"; }; '
            'fetch_and_cache_key_in_mac MY_VAR fetcher arg1 arg2'
        )
        assert result.returncode == 0
        assert result.stdout == "arg1 arg2"

    def test_propagates_status_1_and_does_not_cache_when_fetcher_absent(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'CALLS=$(mktemp); trap \'rm -f "${CALLS}"\' EXIT; '
            'put_key_in_mac() { printf "called" >> "${CALLS}"; }; '
            'fetcher() { return 1; }; '
            'rc=0; fetch_and_cache_key_in_mac MY_VAR fetcher || rc=$?; '
            'printf "%s:[%s]" "${rc}" "$(cat "${CALLS}")"'
        )
        assert result.returncode == 0
        assert result.stdout == "1:[]"

    def test_propagates_status_2_and_does_not_cache_when_fetcher_errored(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'CALLS=$(mktemp); trap \'rm -f "${CALLS}"\' EXIT; '
            'put_key_in_mac() { printf "called" >> "${CALLS}"; }; '
            'fetcher() { return 2; }; '
            'rc=0; fetch_and_cache_key_in_mac MY_VAR fetcher || rc=$?; '
            'printf "%s:[%s]" "${rc}" "$(cat "${CALLS}")"'
        )
        assert result.returncode == 0
        assert result.stdout == "2:[]"


class TestSetKey:
    def test_exports_value_to_child_process_when_env_var_is_set(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'expire_key_in_mac() { :; }; '
            'export MY_VAR=preset-value; '
            'set_key MY_VAR; '
            'bash -c \'printf "%s" "${MY_VAR:-NOT_EXPORTED}"\''
        )
        assert result.returncode == 0
        assert result.stdout == "preset-value"

    def test_env_takes_priority_over_keychain(self) -> None:
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'get_key_from_mac() { printf "mac-value"; }; '
            'export MY_VAR=env-value; '
            'set_key MY_VAR; '
            'printf "%s" "${MY_VAR}"'
        )
        assert result.returncode == 0
        assert result.stdout == "env-value"

    def test_keychain_used_when_env_unset(self) -> None:
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'get_key_from_mac() { printf "mac-value"; }; '
            'unset MY_VAR; '
            'set_key MY_VAR; '
            'printf "%s" "${MY_VAR}"'
        )
        assert result.returncode == 0
        assert result.stdout == "mac-value"

    @pytest.mark.parametrize("source_stub, expected", _FETCHED_SOURCES)
    def test_fetched_source_used_when_env_and_keychain_fail(
        self, source_stub: str, expected: str
    ) -> None:
        result = _run(
            f'source "{SHLIB}"; {_STUBS}{source_stub}'
            'unset MY_VAR; '
            'set_key MY_VAR; '
            'printf "%s" "${MY_VAR}"'
        )
        assert result.returncode == 0
        assert result.stdout == expected

    def test_returns_nonzero_when_all_sources_fail(self) -> None:
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'unset MY_VAR; '
            'set_key MY_VAR'
        )
        assert result.returncode != 0

    def test_fetched_source_result_cached_in_keychain(self) -> None:
        # set_key routes its remote sources through fetch_and_cache_key_in_mac
        # (whose caching is covered on its own); this guards that wiring. One
        # source suffices -- both wrappers delegate to the same helper.
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'CALLS=$(mktemp); trap \'rm -f "${CALLS}"\' EXIT; '
            'get_key_from_1password() { printf "op-value"; }; '
            'put_key_in_mac() { printf "%s %s" "$1" "$2" >> "${CALLS}"; }; '
            'unset MY_VAR; '
            'set_key MY_VAR; '
            'cat "${CALLS}"'
        )
        assert result.returncode == 0
        assert result.stdout == "MY_VAR op-value"

    def test_keychain_hit_does_not_cache(self) -> None:
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'CALLS=$(mktemp); trap \'rm -f "${CALLS}"\' EXIT; '
            'get_key_from_mac() { printf "mac-value"; }; '
            'put_key_in_mac() { printf "called" >> "${CALLS}"; }; '
            'unset MY_VAR; '
            'set_key MY_VAR; '
            'cat "${CALLS}"'
        )
        assert result.returncode == 0
        assert result.stdout == ""

    def test_env_hit_does_not_cache(self) -> None:
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'CALLS=$(mktemp); trap \'rm -f "${CALLS}"\' EXIT; '
            'put_key_in_mac() { printf "called" >> "${CALLS}"; }; '
            'export MY_VAR=env-value; '
            'set_key MY_VAR; '
            'cat "${CALLS}"'
        )
        assert result.returncode == 0
        assert result.stdout == ""


class TestSetKeyFailureModes:
    def test_absent_is_silent_and_returns_1(self) -> None:
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'unset MY_VAR; '
            'set_key MY_VAR'
        )
        assert result.returncode == 1
        assert result.stderr == ""

    def test_errored_warns_on_stderr_and_returns_2(self) -> None:
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'get_key_from_aws() { return 2; }; '
            'unset MY_VAR; '
            'set_key MY_VAR'
        )
        assert result.returncode == 2
        assert "reachable but failed" in result.stderr

    def test_later_success_overrides_an_errored_source(self) -> None:
        # A source that errored must not warn when a subsequent source supplies
        # the key: no crying wolf when telemetry actually went out.
        result = _run(
            f'source "{SHLIB}"; {_STUBS}'
            'get_key_from_mac() { return 2; }; '
            'get_key_from_1password() { printf "op-value"; }; '
            'unset MY_VAR; '
            'set_key MY_VAR; '
            'printf "%s" "${MY_VAR}"'
        )
        assert result.returncode == 0
        assert result.stdout == "op-value"
        assert result.stderr == ""


# `security` stub printing a Keychain attribute dump whose "mdat" field carries
# the given 14-digit timestamp. The actual digits are irrelevant because `date`
# is stubbed too; they only need to satisfy expire_key_in_mac's mdat regex.
_SEC_WITH_MDAT = (
    "security() { printf '%s\\n' '\"mdat\"<timedate>=\"20260602120000'; }; "
)
# `security` stub whose dump has no "mdat" line (simulates a missing entry).
_SEC_NO_MDAT = 'security() { printf "class genp\\n"; }; '
# `security` stub that fails outright (simulates lookup error / locked keychain).
_SEC_FAILS = 'security() { return 1; }; '

# `del_key_from_mac` stub that reports the key it was asked to delete, so a test
# can assert whether (and with what argument) deletion happened.
_DEL_STUB = 'del_key_from_mac() { printf "DELETED:%s" "$1"; }; '


def _date_stub(mtime: int, now: int) -> str:
    """`date` stub: the `-j` parse call yields *mtime*; any other call yields *now*."""
    return (
        'date() { if [[ "$1" == "-j" ]]; then '
        f'printf "%s" "{mtime}"; else printf "%s" "{now}"; fi; }}; '
    )


_TTL = 43200  # 12 hours, passed to expire_key_in_mac under test


class TestExpireKeyInMac:
    def _run(self, security: str, date: str) -> object:
        return _run(
            f'source "{SHLIB}"; '
            f'{security}{date}{_DEL_STUB}'
            f'expire_key_in_mac LINEAR_API_KEY {_TTL}'
        )

    def test_deletes_key_when_older_than_ttl(self) -> None:
        result = self._run(_SEC_WITH_MDAT, _date_stub(1_000_000_000, 1_000_000_000 + _TTL + 5000))
        assert result.returncode == 0
        assert result.stdout == "DELETED:LINEAR_API_KEY"

    def test_deletes_key_when_just_over_ttl(self) -> None:
        result = self._run(_SEC_WITH_MDAT, _date_stub(1_000_000_000, 1_000_000_000 + _TTL + 1))
        assert result.returncode == 0
        assert result.stdout == "DELETED:LINEAR_API_KEY"

    def test_does_not_delete_when_exactly_at_ttl(self) -> None:
        result = self._run(_SEC_WITH_MDAT, _date_stub(1_000_000_000, 1_000_000_000 + _TTL))
        assert result.returncode == 0
        assert result.stdout == ""

    def test_does_not_delete_when_within_ttl(self) -> None:
        result = self._run(_SEC_WITH_MDAT, _date_stub(1_000_000_000, 1_000_000_000 + 100))
        assert result.returncode == 0
        assert result.stdout == ""

    def test_does_not_delete_when_key_absent(self) -> None:
        result = self._run(_SEC_NO_MDAT, _date_stub(1, 2))
        assert result.returncode == 0
        assert result.stdout == ""

    def test_does_not_delete_when_lookup_fails(self) -> None:
        result = self._run(_SEC_FAILS, _date_stub(1, 2))
        assert result.returncode == 0
        assert result.stdout == ""


class TestGetKeyFromMac:
    """get_key_from_mac classifies Keychain outcomes into the 0/1/2 ladder."""

    def test_prints_value_and_succeeds_when_found(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            'security() { printf "mac-secret"; }; '
            'get_key_from_mac LINEAR_API_KEY'
        )
        assert result.returncode == 0
        assert result.stdout == "mac-secret"

    def test_absent_when_item_not_found(self) -> None:
        # 44 == errSecItemNotFound: nothing stored → absent (quiet).
        result = _run(
            f'source "{SHLIB}"; '
            'security() { return 44; }; '
            'get_key_from_mac LINEAR_API_KEY'
        )
        assert result.returncode == 1
        assert result.stdout == ""

    def test_errored_when_lookup_fails_otherwise(self) -> None:
        # e.g. 128 when the user denies the access prompt → reachable but failed.
        result = _run(
            f'source "{SHLIB}"; '
            'security() { return 128; }; '
            'get_key_from_mac LINEAR_API_KEY'
        )
        assert result.returncode == 2

    def test_absent_when_security_not_installed(self) -> None:
        # Empty PATH and no `security` stub: probe_key_source returns 127, which
        # get_key_from_mac treats as absent (quiet), never an error.
        result = _run(
            f'source "{SHLIB}"; '
            '( PATH=""; get_key_from_mac LINEAR_API_KEY )'
        )
        assert result.returncode == 1


# get_key_from_1password and get_key_from_aws share probe_key_source's
# three-state shape (found / absent / errored); they differ only in the binary
# probed, the calling convention, and the message text each CLI emits. The cases
# below capture those differences so one parametrized body covers both sources.
@dataclass(frozen=True)
class _CliKeySource:
    id: str           # parametrize label
    func: str         # function under test
    args: str         # arguments it expects
    binary: str       # CLI command it shells out to
    secret: str       # value the CLI prints on success
    absent_msg: str   # CLI stderr for a missing item/secret -> absent (1)
    errored_msg: str  # CLI stderr for a genuine runtime failure -> errored (2)
    fail_code: int    # exit code the CLI uses when it fails


_CLI_KEY_SOURCES = [
    _CliKeySource(
        id="1password",
        func="get_key_from_1password",
        args="LINEAR_API_KEY",
        binary="op",
        secret="op-secret",
        absent_msg='ERROR: \\"LINEAR_API_KEY\\" isn\\047t an item.',
        errored_msg="ERROR: you are not currently signed in.",
        fail_code=1,
    ),
    _CliKeySource(
        id="aws",
        func="get_key_from_aws",
        args="prof secret/id",
        binary="aws",
        secret="aws-secret",
        absent_msg="ResourceNotFoundException: Secrets Manager",
        errored_msg="ExpiredTokenException: token expired",
        fail_code=254,
    ),
]
_CLI_IDS = [s.id for s in _CLI_KEY_SOURCES]


class TestCliKeySources:
    """The CLI-backed key sources classify outcomes into the 0/1/2 ladder."""

    @pytest.mark.parametrize("src", _CLI_KEY_SOURCES, ids=_CLI_IDS)
    def test_succeeds_when_cli_returns_value(self, src: _CliKeySource) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            f'{src.binary}() {{ printf "{src.secret}"; }}; '
            f"{src.func} {src.args}"
        )
        assert result.returncode == 0
        assert result.stdout == src.secret

    @pytest.mark.parametrize("src", _CLI_KEY_SOURCES, ids=_CLI_IDS)
    def test_absent_when_cli_not_installed(self, src: _CliKeySource) -> None:
        # Empty PATH and no stub: the binary is simply missing, so the source is
        # absent (quiet), never an error.
        result = _run(
            f'source "{SHLIB}"; '
            f'( PATH=""; {src.func} {src.args} )'
        )
        assert result.returncode == 1

    @pytest.mark.parametrize("src", _CLI_KEY_SOURCES, ids=_CLI_IDS)
    def test_absent_when_secret_missing(self, src: _CliKeySource) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            f'{src.binary}() {{ printf "{src.absent_msg}" >&2; return {src.fail_code}; }}; '
            f"{src.func} {src.args}"
        )
        assert result.returncode == 1

    @pytest.mark.parametrize("src", _CLI_KEY_SOURCES, ids=_CLI_IDS)
    def test_errored_when_cli_fails_otherwise(self, src: _CliKeySource) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            f'{src.binary}() {{ printf "{src.errored_msg}" >&2; return {src.fail_code}; }}; '
            f"{src.func} {src.args}"
        )
        assert result.returncode == 2
