#!/usr/bin/env python3
"""Wait for all Juju units in the model to be active/idle.

Uses the jubilant library for type-safe, structured Juju status polling.

Usage (called by wait_idle_jubilant() in helpers.sh):
    python3 wait_idle.py [-t SECONDS] [-i SECONDS] [-b APP1,APP2,...] [-v]

Options:
    -t, --timeout SECONDS        Max wait time (default: 600).
    -i, --interval SECONDS       Poll interval (default: 30).
    -b, --allow-blocked APPS     Comma-separated apps allowed to be blocked.
    -v, --verbose                Show per-field status diffs from jubilant.

Exit codes:
    0  All units active/idle.
    1  Timed out or error.
"""

import argparse
import logging
import sys
from collections.abc import Callable

import jubilant

logger = logging.getLogger("jubilant.wait")


def _build_ready(allow_blocked: set[str]) -> Callable[[jubilant.Status], bool]:
    """Return a ready callable for ``Juju.wait()``.

    Units belonging to apps in *allow_blocked* may be ``blocked/idle`` instead
    of ``active/idle``.  All other units must be ``active/idle``.
    """

    def ready(status: jubilant.Status) -> bool:
        if not status.apps:
            return False
        for app_name, app in status.apps.items():
            if not app.units:
                return False
            for unit in app.units.values():
                ws = unit.workload_status.current
                js = unit.juju_status.current
                if ws == "active" and js == "idle":
                    continue
                if app_name in allow_blocked and ws == "blocked" and js == "idle":
                    continue
                return False
        return True

    return ready


def _print_status(juju: jubilant.Juju) -> None:
    """Print ``juju status``, ignoring errors if the CLI itself fails."""
    try:
        print(juju.cli("status"))
    except jubilant.CLIError as exc:
        print(f"Could not retrieve juju status: {exc}", file=sys.stderr)


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Wait for all Juju units to be active/idle.",
    )
    parser.add_argument("-t", "--timeout", type=int, default=600)
    parser.add_argument("-i", "--interval", type=int, default=30)
    parser.add_argument(
        "-b", "--allow-blocked", type=str, default="", dest="allow_blocked",
    )
    parser.add_argument(
        "-v", "--verbose", action="store_true",
        help="Show detailed per-field status diffs from jubilant.",
    )
    args = parser.parse_args()

    logging.basicConfig(level=logging.WARNING, format="%(message)s")
    if args.verbose:
        logger.setLevel(logging.INFO)

    allow_blocked = {a.strip() for a in args.allow_blocked.split(",") if a.strip()}

    juju = jubilant.Juju()

    print(
        f"Waiting for all Juju units to be active/idle "
        f"(timeout={args.timeout}s, poll={args.interval}s, jubilant)\u2026"
    )

    try:
        juju.wait(
            _build_ready(allow_blocked),
            timeout=args.timeout,
            delay=args.interval,
        )
    except TimeoutError:
        print(f"Timed out after {args.timeout}s. Final status:", file=sys.stderr)
        _print_status(juju)
        sys.exit(1)
    except jubilant.CLIError as exc:
        print(f"Juju CLI error during wait: {exc}", file=sys.stderr)
        sys.exit(1)

    print("All units active/idle.")
    _print_status(juju)


if __name__ == "__main__":
    main()
