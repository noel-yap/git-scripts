"""Tests for functions in workspace.shlib.

Each function is invoked in a fresh `bash` subprocess that sources the library.
"""

from __future__ import annotations

from pathlib import Path

from test_utils import _run

SHLIB = Path(__file__).parent.parent / "workspace.shlib"


class TestSetupWorkspaceEnv:
    """setup_workspace_env creates ./tmp and a direnv .envrc exporting TMPDIR as
    ${PWD}/tmp, leaving any existing .envrc untouched.
    """

    def test_creates_tmp_directory_and_envrc(self, tmp_path: Path) -> None:
        result = _run(
            f'source "{SHLIB}"; cd "{tmp_path}"; setup_workspace_env'
        )
        assert result.returncode == 0
        assert (tmp_path / "tmp").is_dir()
        assert (tmp_path / ".envrc").read_text() == 'export TMPDIR="${PWD}/tmp"\n'

    def test_does_not_overwrite_existing_envrc(self, tmp_path: Path) -> None:
        (tmp_path / ".envrc").write_text("existing\n")
        result = _run(
            f'source "{SHLIB}"; cd "{tmp_path}"; setup_workspace_env'
        )
        assert result.returncode == 0
        assert (tmp_path / "tmp").is_dir()
        assert (tmp_path / ".envrc").read_text() == "existing\n"
