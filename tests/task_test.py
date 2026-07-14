"""Tests for functions in task.shlib.

Each function is invoked in a fresh `bash` subprocess that sources the library.
The shell runs under strict flags (`set -e -o pipefail -u; shopt -s
inherit_errexit`) so tests catch bugs that only manifest under those flags.
"""

from __future__ import annotations

from pathlib import Path

from test_utils import _run

SHLIB = Path(__file__).parent.parent / "task.shlib"

# Stubs `security` so set_key's Keychain cache-expiry path fires: `find`
# reports a mdat old enough to be stale, and `delete` reports the deletion on
# stdout — exactly the output that must never leak into a summary or slug.
_STALE_KEYCHAIN_SECURITY_STUB = (
    'security() { case "$1" in '
    "find-generic-password) printf '%s\\n' "
    "'\"mdat\"<timedate>=\"20000101000000Z\"' ;; "
    "delete-generic-password) echo 'password has been deleted.' ;; "
    "esac; }; "
)

# Makes every set_key source report "absent" so a real key on the developer's
# machine (Keychain/1Password/AWS) can't leak into a test that asserts an unset
# key. security 44 == Keychain item absent; op 127 == 1Password CLI not
# installed; unsetting AWS_PROFILE/AWS_PREFIX skips the AWS source.
_ABSENT_KEY_SOURCES_STUB = (
    "unset AWS_PROFILE AWS_PREFIX; "
    "security() { return 44; }; "
    "op() { return 127; }; "
)


class TestGetTaskId:
    """get_task_id extracts a Linear key from a linear.app issue URL, or a
    Jira key from a URL's selectedIssue query parameter or /browse/ path
    segment, and otherwise returns its argument unchanged. All URL forms
    require an https scheme. It dispatches to get_task_id_from_linear_url,
    get_task_id_from_jira_url, and get_task_id_fallthrough in that order via
    coalesce, so its output carries no trailing newline.
    """

    def test_extracts_key_from_selected_issue_query_parameter(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://jira.example.com/board?selectedIssue=ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_strips_trailing_query_parameters_after_selected_issue(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://jira.example.com/board?selectedIssue=ABC-123&view=detail'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_extracts_key_from_browse_path_segment(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://jira.example.com/browse/ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_selected_issue_takes_precedence_over_browse_segment(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://jira.example.com/browse/WRONG-999?selectedIssue=ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_extracts_key_from_linear_issue_url(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://linear.app/qad-redzone/issue/ABC-123/implement-extraction-for-clarity-skill'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_extracts_key_from_linear_issue_url_without_title_slug(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://linear.app/qad-redzone/issue/ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_strips_query_string_from_linear_issue_url(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://linear.app/qad-redzone/issue/ABC-123?comment=abc'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_linear_branch_wins_over_jira_markers_in_linear_title_slug(self) -> None:
        # A Linear title slug that happens to contain a Jira marker must not
        # be parsed by the Jira branches.
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://linear.app/qad-redzone/issue/ABC-123/fix-browse-page?selectedIssue=WRONG-1'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_returns_unchanged_when_issue_segment_present_but_not_linear_app(self) -> None:
        # The /issue/ marker alone must not trigger Linear parsing; the
        # linear.app host is required (and no Jira marker is present here).
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://other.example.com/issue/ABC-123/title'"
        )
        assert result.returncode == 0
        assert result.stdout == "https://other.example.com/issue/ABC-123/title"

    def test_returns_plain_task_key_unchanged(self) -> None:
        result = _run(f'source "{SHLIB}"; get_task_id ABC-123')
        assert result.returncode == 0
        assert result.stdout == "ABC-123"

    def test_returns_unchanged_when_https_url_has_neither_marker(self) -> None:
        # https, but no selectedIssue and no /browse/: falls through to the
        # else branch and is returned verbatim.
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id 'https://jira.example.com/dashboard'"
        )
        assert result.returncode == 0
        assert result.stdout == "https://jira.example.com/dashboard"

    def test_returns_unchanged_when_selected_issue_present_but_not_https(self) -> None:
        # The selectedIssue marker is present but the scheme is not https, so
        # the first branch must not fire -- the scheme is required.
        result = _run(f'source "{SHLIB}"; get_task_id selectedIssue=ABC-123')
        assert result.returncode == 0
        assert result.stdout == "selectedIssue=ABC-123"

    def test_returns_unchanged_when_browse_present_but_not_https(self) -> None:
        # The /browse/ marker is present but the scheme is not https, so the
        # elif branch must not fire.
        result = _run(f'source "{SHLIB}"; get_task_id /browse/ABC-123')
        assert result.returncode == 0
        assert result.stdout == "/browse/ABC-123"


class TestGetTaskIdFromLinearUrl:
    """get_task_id_from_linear_url extracts the key from a linear.app issue
    URL and returns nonzero for anything else.
    """

    def test_extracts_key_from_linear_issue_url(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id_from_linear_url 'https://linear.app/qad-redzone/issue/ABC-123/some-title'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"

    def test_returns_nonzero_for_non_linear_url(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id_from_linear_url 'https://jira.example.com/browse/ABC-123'"
        )
        assert result.returncode != 0
        assert result.stdout == ""

    def test_returns_nonzero_for_bare_key(self) -> None:
        result = _run(f'source "{SHLIB}"; get_task_id_from_linear_url ABC-123')
        assert result.returncode != 0
        assert result.stdout == ""


class TestGetTaskIdFromJiraUrl:
    """get_task_id_from_jira_url extracts the key from a Jira selectedIssue or
    /browse/ URL and returns nonzero for anything else.
    """

    def test_extracts_key_from_browse_url(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id_from_jira_url 'https://jira.example.com/browse/ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"

    def test_extracts_key_from_selected_issue_url(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id_from_jira_url 'https://jira.example.com/board?selectedIssue=ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"

    def test_returns_nonzero_for_non_jira_url(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_id_from_jira_url 'https://jira.example.com/dashboard'"
        )
        assert result.returncode != 0
        assert result.stdout == ""

    def test_returns_nonzero_for_bare_key(self) -> None:
        result = _run(f'source "{SHLIB}"; get_task_id_from_jira_url ABC-123')
        assert result.returncode != 0
        assert result.stdout == ""


class TestGetTaskIdFallthrough:
    """get_task_id_fallthrough returns its argument unchanged."""

    def test_returns_argument_unchanged(self) -> None:
        result = _run(f'source "{SHLIB}"; get_task_id_fallthrough ABC-123')
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"


class TestGetTaskSummaryFromJira:
    """get_task_summary_from_jira pipes acli's JSON through jq to read the
    summary field when ATLASSIAN_API_TOKEN is set.
    """

    def test_returns_summary_field_from_acli_json(self) -> None:
        # ATLASSIAN_API_TOKEN is exported, so set_key resolves it from the
        # environment; stub `security` (return 44 == item absent) so set_key's
        # Keychain expiry step touches no real Keychain.
        result = _run(
            f'source "{SHLIB}"; '
            "export ATLASSIAN_API_TOKEN=test; "
            "security() { return 44; }; "
            "acli() { printf '%s' '{\"fields\":{\"summary\":\"Do stuff\"}}'; }; "
            "get_task_summary_from_jira ABC-123"
        )
        assert result.returncode == 0
        assert result.stdout == "Do stuff\n"

    def test_keychain_expiry_output_does_not_pollute_summary(self) -> None:
        # A stale Keychain cache entry makes set_key delete it, and `security
        # delete-generic-password` reports the deletion on stdout. That report
        # must not be captured as part of the summary.
        result = _run(
            f'source "{SHLIB}"; '
            "export ATLASSIAN_API_TOKEN=test; "
            + _STALE_KEYCHAIN_SECURITY_STUB
            + "acli() { printf '%s' '{\"fields\":{\"summary\":\"Do stuff\"}}'; }; "
            "get_task_summary_from_jira ABC-123"
        )
        assert result.returncode == 0
        assert result.stdout == "Do stuff\n"

    def test_emits_nothing_when_summary_field_is_absent(self) -> None:
        # A nonexistent workitem yields JSON without a summary; jq's `// empty`
        # must emit nothing rather than the literal string "null".
        result = _run(
            f'source "{SHLIB}"; '
            "export ATLASSIAN_API_TOKEN=test; "
            "security() { return 44; }; "
            "acli() { printf '%s' '{\"fields\":{}}'; }; "
            "get_task_summary_from_jira ABC-123"
        )
        assert result.stdout == ""

    def test_returns_nonzero_when_atlassian_api_token_unset(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "unset ATLASSIAN_API_TOKEN; "
            + _ABSENT_KEY_SOURCES_STUB
            + "acli() { echo 'should-not-run' >&2; return 1; }; "
            "get_task_summary_from_jira ABC-123"
        )
        assert result.returncode != 0
        assert result.stdout == ""
        assert "should-not-run" not in result.stderr


class TestGetTaskSummaryFromLinear:
    """get_task_summary_from_linear posts a GraphQL query and reads the issue
    title from the response.
    """

    def test_returns_issue_title_from_graphql_response(self) -> None:
        # LINEAR_API_KEY is exported, so set_key resolves it from the
        # environment; stub `security` (return 44 == item absent) so set_key's
        # Keychain expiry step touches no real Keychain.
        result = _run(
            f'source "{SHLIB}"; '
            "export LINEAR_API_KEY=test; "
            "security() { return 44; }; "
            "curl() { printf '%s' '{\"data\":{\"issue\":{\"title\":\"Do stuff\"}}}'; }; "
            "get_task_summary_from_linear ENG-123"
        )
        assert result.returncode == 0
        assert result.stdout == "Do stuff\n"

    def test_keychain_expiry_output_does_not_pollute_summary(self) -> None:
        # A stale Keychain cache entry makes set_key delete it, and `security
        # delete-generic-password` reports the deletion on stdout. That report
        # must not be captured as part of the summary.
        result = _run(
            f'source "{SHLIB}"; '
            "export LINEAR_API_KEY=test; "
            + _STALE_KEYCHAIN_SECURITY_STUB
            + "curl() { printf '%s' '{\"data\":{\"issue\":{\"title\":\"Do stuff\"}}}'; }; "
            "get_task_summary_from_linear ENG-123"
        )
        assert result.returncode == 0
        assert result.stdout == "Do stuff\n"

    def test_emits_nothing_when_issue_is_not_found(self) -> None:
        # A nonexistent issue yields a null `data.issue`; jq's `// empty` must
        # emit nothing rather than the literal string "null".
        result = _run(
            f'source "{SHLIB}"; '
            "export LINEAR_API_KEY=test; "
            "security() { return 44; }; "
            "curl() { printf '%s' '{\"data\":{\"issue\":null}}'; }; "
            "get_task_summary_from_linear ENG-123"
        )
        assert result.stdout == ""


class TestGetTaskSummary:
    """get_task_summary tries Linear first and falls back to Jira, returning the
    first source that yields a non-empty summary.
    """

    def test_returns_linear_summary_when_linear_succeeds(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary_from_linear() { printf 'linear-summary'; }; "
            "get_task_summary_from_jira() { printf 'jira-summary'; }; "
            "get_task_summary ENG-123"
        )
        assert result.returncode == 0
        assert result.stdout == "linear-summary"

    def test_falls_back_to_jira_when_linear_yields_nothing(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary_from_linear() { return 1; }; "
            "get_task_summary_from_jira() { printf 'jira-summary'; }; "
            "get_task_summary ENG-123"
        )
        assert result.returncode == 0
        assert result.stdout == "jira-summary"

    def test_passes_task_through_to_the_chosen_source(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary_from_linear() { return 1; }; "
            "get_task_summary_from_jira() { printf 'summary-of-%s' \"$1\"; }; "
            "get_task_summary ENG-123"
        )
        assert result.returncode == 0
        assert result.stdout == "summary-of-ENG-123"

    def test_returns_nonzero_when_all_sources_yield_nothing(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary_from_linear() { return 1; }; "
            "get_task_summary_from_jira() { return 1; }; "
            "get_task_summary ENG-123"
        )
        assert result.returncode != 0
        assert result.stdout == ""

    def test_skips_jira_when_atlassian_api_token_unset(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "unset ATLASSIAN_API_TOKEN; "
            + _ABSENT_KEY_SOURCES_STUB
            + "get_task_summary_from_linear() { return 1; }; "
            "acli() { echo 'should-not-run' >&2; return 1; }; "
            "get_task_summary ENG-123"
        )
        assert result.returncode != 0
        assert result.stdout == ""
        assert "should-not-run" not in result.stderr


# A 63-character key sits just under the 64-character truncation threshold; a
# 64-character key sits just at it.
_KEY_63 = "x" * 63
_KEY_64 = "x" * 64


class TestGetTaskSlug:
    """get_task_slug builds a branch/directory slug. When a task summary is
    available it joins the key to the summary as `TASK：SUMMARY`; otherwise it
    uses the key alone. Either form is truncated to 63 characters plus `⋯` once
    it reaches 64 characters.
    """

    def test_returns_key_unchanged_when_no_summary_available_and_key_is_short(
        self,
    ) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary() { return 1; }; "
            "get_task_slug do-something"
        )
        assert result.returncode == 0
        assert result.stdout == "do-something\n"
        assert result.stderr == ""

    def test_does_not_truncate_when_no_summary_available_and_key_is_63_characters(
        self,
    ) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary() { return 1; }; "
            f"get_task_slug {_KEY_63}"
        )
        assert result.returncode == 0
        assert result.stdout == _KEY_63 + "\n"

    def test_truncates_when_no_summary_available_and_key_is_64_characters(
        self,
    ) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary() { return 1; }; "
            f"get_task_slug {_KEY_64}"
        )
        assert result.returncode == 0
        assert result.stdout == _KEY_64[:63] + "⋯\n"

    def test_joins_key_and_summary_when_summary_available_and_result_is_short(
        self,
    ) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary() { printf 'Dostuff'; }; "
            "get_task_slug ABC-123"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123：Dostuff\n"
        assert result.stderr == ""

    def test_joins_key_and_linear_summary_when_jira_token_unset(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "unset ATLASSIAN_API_TOKEN; "
            "export LINEAR_API_KEY=test; "
            "security() { return 44; }; "
            "get_task_summary_from_linear() { printf 'LinearSummary'; }; "
            "get_task_slug ENG-123"
        )
        assert result.returncode == 0
        assert result.stdout == "ENG-123：LinearSummary\n"

    def test_keychain_expiry_output_does_not_pollute_slug(self) -> None:
        # A stale Keychain cache entry makes set_key delete it, and `security
        # delete-generic-password` reports the deletion on stdout. The slug
        # must contain only the key and summary (spaces unicodified to en
        # spaces), never that report.
        result = _run(
            f'source "{SHLIB}"; '
            "export LINEAR_API_KEY=test; "
            + _STALE_KEYCHAIN_SECURITY_STUB
            + "curl() { printf '%s' '{\"data\":{\"issue\":{\"title\":\"Do stuff\"}}}'; }; "
            "get_task_slug ENG-123"
        )
        assert result.returncode == 0
        assert result.stdout == "ENG-123：Do stuff\n"

    def test_truncates_when_summary_available_and_result_reaches_64_characters(
        self,
    ) -> None:
        # ABC-123 (7) + ： (1) + 56 a's = 64 chars -> truncated to 63 + ⋯.
        summary = "a" * 56
        expected = ("ABC-123：" + "a" * 56)[:63] + "⋯"
        result = _run(
            f'source "{SHLIB}"; '
            f"get_task_summary() {{ printf '{summary}'; }}; "
            "get_task_slug ABC-123"
        )
        assert result.returncode == 0
        assert result.stdout == expected + "\n"
        assert result.stderr == ""
