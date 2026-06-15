"""Tests for functions in task.shlib.

Each function is invoked in a fresh `bash` subprocess that sources the library.
The shell runs under strict flags (`set -e -o pipefail -u; shopt -s
inherit_errexit`) so tests catch bugs that only manifest under those flags.
"""

from __future__ import annotations

from pathlib import Path

from test_utils import _run

SHLIB = Path(__file__).parent.parent / "task.shlib"


class TestGetTask:
    """get_task extracts a Jira key from a URL's selectedIssue query parameter
    or /browse/ path segment, and otherwise returns its argument unchanged.
    Both URL forms require an https scheme.
    """

    def test_extracts_key_from_selected_issue_query_parameter(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task 'https://jira.example.com/board?selectedIssue=ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"

    def test_strips_trailing_query_parameters_after_selected_issue(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task 'https://jira.example.com/board?selectedIssue=ABC-123&view=detail'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"

    def test_extracts_key_from_browse_path_segment(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task 'https://jira.example.com/browse/ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"

    def test_selected_issue_takes_precedence_over_browse_segment(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task 'https://jira.example.com/browse/WRONG-999?selectedIssue=ABC-123'"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"

    def test_returns_plain_task_key_unchanged(self) -> None:
        result = _run(f'source "{SHLIB}"; get_task ABC-123')
        assert result.returncode == 0
        assert result.stdout == "ABC-123\n"

    def test_returns_unchanged_when_https_url_has_neither_marker(self) -> None:
        # https, but no selectedIssue and no /browse/: falls through to the
        # else branch and is returned verbatim.
        result = _run(
            f'source "{SHLIB}"; '
            "get_task 'https://jira.example.com/dashboard'"
        )
        assert result.returncode == 0
        assert result.stdout == "https://jira.example.com/dashboard\n"

    def test_returns_unchanged_when_selected_issue_present_but_not_https(self) -> None:
        # The selectedIssue marker is present but the scheme is not https, so
        # the first branch must not fire -- the scheme is required.
        result = _run(f'source "{SHLIB}"; get_task selectedIssue=ABC-123')
        assert result.returncode == 0
        assert result.stdout == "selectedIssue=ABC-123\n"

    def test_returns_unchanged_when_browse_present_but_not_https(self) -> None:
        # The /browse/ marker is present but the scheme is not https, so the
        # elif branch must not fire.
        result = _run(f'source "{SHLIB}"; get_task /browse/ABC-123')
        assert result.returncode == 0
        assert result.stdout == "/browse/ABC-123\n"


class TestGetTaskSummaryFromJira:
    """get_task_summary_from_jira pipes acli's JSON through jq to read the
    summary field.
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


# A 63-character key sits just under the 64-character truncation threshold; a
# 64-character key sits just at it.
_KEY_63 = "x" * 63
_KEY_64 = "x" * 64


class TestGetTaskSlug:
    """get_task_slug builds a branch/directory slug. Without ATLASSIAN_API_TOKEN
    it uses the key alone; with it, the key is joined to the Jira summary as
    `TASK：SUMMARY`. Either form is truncated to 63 characters plus `⋯` once it
    reaches 64 characters.
    """

    def test_returns_key_unchanged_when_no_token_and_key_is_short(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "unset ATLASSIAN_API_TOKEN; "
            "get_task_slug do-something"
        )
        assert result.returncode == 0
        assert result.stdout == "do-something\n"
        assert result.stderr == ""

    def test_does_not_truncate_when_no_token_and_key_is_63_characters(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "unset ATLASSIAN_API_TOKEN; "
            f"get_task_slug {_KEY_63}"
        )
        assert result.returncode == 0
        assert result.stdout == _KEY_63 + "\n"

    def test_truncates_when_no_token_and_key_is_64_characters(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "unset ATLASSIAN_API_TOKEN; "
            f"get_task_slug {_KEY_64}"
        )
        assert result.returncode == 0
        assert result.stdout == _KEY_64[:63] + "⋯\n"

    def test_joins_key_and_summary_when_token_set_and_result_is_short(self) -> None:
        result = _run(
            f'source "{SHLIB}"; '
            "get_task_summary() { printf 'Dostuff'; }; "
            "get_task_slug ABC-123"
        )
        assert result.returncode == 0
        assert result.stdout == "ABC-123：Dostuff\n"
        assert result.stderr == ""

    def test_truncates_when_token_set_and_result_reaches_64_characters(self) -> None:
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
