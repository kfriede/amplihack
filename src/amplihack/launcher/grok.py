"""Grok Build CLI launcher - wrapper around Grok Build command."""

import os
import subprocess
import sys
from pathlib import Path


def check_grok() -> bool:
    """Check if Grok Build CLI is installed."""
    try:
        subprocess.run(["grok", "--version"], capture_output=True, timeout=5, check=False)
        return True
    except (FileNotFoundError, subprocess.TimeoutExpired):
        return False


def _get_current_grok_version() -> str | None:
    """Get the currently installed Grok Build CLI version."""
    try:
        result = subprocess.run(
            ["grok", "--version"], capture_output=True, text=True, timeout=10, check=False
        )
        if result.returncode != 0:
            return None
        # Output format: "grok 0.1.216 (b13974465)"
        parts = result.stdout.strip().split()
        return parts[1] if len(parts) >= 2 else None
    except (FileNotFoundError, subprocess.TimeoutExpired, OSError, IndexError):
        return None


def _compare_versions(current: str, latest: str) -> bool:
    """Return True if latest > current using semantic version comparison."""
    try:
        cur = tuple(int(x) for x in current.lstrip("v").split("."))
        lat = tuple(int(x) for x in latest.lstrip("v").split("."))
        return lat > cur
    except (ValueError, AttributeError):
        return False


def ensure_latest_grok() -> bool:
    """Auto-update Grok Build CLI if an update is available.

    Set AMPLIHACK_SKIP_UPDATE=1 to bypass.

    Returns:
        True if up-to-date or updated successfully, False on failure.
    """
    if os.environ.get("AMPLIHACK_SKIP_UPDATE", "") == "1":
        return True

    if not check_grok():
        return True  # not installed yet — let install_grok() handle it

    try:
        current = _get_current_grok_version()
        if current is None:
            return True

        # Grok uses its own update mechanism
        result = subprocess.run(
            ["grok", "update", "--check"],
            capture_output=True,
            text=True,
            timeout=15,
            check=False,
        )
        if result.returncode != 0 or "up to date" in result.stdout.lower():
            return True  # already up-to-date or check failed

        print(f"🔄 Grok Build CLI update available (current: {current})")
        update_result = subprocess.run(
            ["grok", "update"],
            capture_output=True,
            text=True,
            timeout=120,
            check=False,
        )
        if update_result.returncode == 0:
            post = _get_current_grok_version() or "latest"
            print(f"✓ Grok Build CLI updated to {post}")
            return True

        print(f"⚠ Grok update failed — continuing with current version")
        return False
    except Exception:
        return False


def install_grok() -> bool:
    """Prompt user to install Grok Build CLI.

    Unlike npm-based CLIs, Grok Build uses its own installer.
    Guide the user to the installation page.
    """
    print("Grok Build CLI is not installed.")
    print("Install it from: https://grok.com/build")
    print("Or if you have the installer available:")
    print("  curl -fsSL https://grok.com/install | bash")
    print()

    if sys.stdin.isatty():
        print("After installing, run 'amplihack grok' again.")

    return False


def launch_grok(args: list[str] | None = None, interactive: bool = True) -> int:
    """Launch Grok Build CLI.

    Grok Build natively reads CLAUDE.md and .claude/skills/, so it picks up
    all amplihack workflows, agents, and skills automatically. This launcher
    handles environment setup and argument translation.

    Args:
        args: Arguments to pass to grok
        interactive: If True, launch interactively

    Returns:
        Exit code
    """
    # Auto-update to latest version before launching
    try:
        ensure_latest_grok()
    except Exception:
        pass  # non-critical — continue with current version

    # Ensure grok is installed
    if not check_grok():
        install_grok()
        return 1

    # Build command
    cmd = ["grok"]
    if args:
        # Grok uses -p for single-turn prompts (same as Claude Code)
        cmd.extend(args)

    # Build explicit env with agent identity and home directory
    env = os.environ.copy()
    from amplihack.launcher import prepare_amplihack_env

    prepare_amplihack_env(env, "grok")

    # Launch using subprocess.run() for proper terminal handling
    result = subprocess.run(cmd, check=False, env=env)
    return result.returncode
