"""General-purpose shell test helpers shared across the pytest suites.

Provides the following building blocks:

  ShellResult — dataclass holding stdout, stderr, and returncode
  _run        — runs a bash script under strict mode
"""

from __future__ import annotations

import subprocess
from dataclasses import dataclass


STRICT_PRELUDE = "set -e; set -o pipefail; set -u; shopt -s inherit_errexit; "


@dataclass(frozen=True)
class ShellResult:
    stdout: str
    stderr: str
    returncode: int


def _run(script: str, *args: str, env: dict[str, str] | None = None) -> ShellResult:
    """Run *script* under strict-mode bash and return its stdout, stderr, and exit code.

    *args* are passed as positional parameters (``$1``, ``$2``, …).
    *env*, if given, replaces the subprocess environment entirely.
    """
    proc = subprocess.run(
        ["bash", "-c", STRICT_PRELUDE + script, "_", *args],
        capture_output=True,
        text=True,
        env=env,
        check=False,
    )
    return ShellResult(stdout=proc.stdout, stderr=proc.stderr, returncode=proc.returncode)