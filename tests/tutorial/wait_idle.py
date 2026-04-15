#!/usr/bin/env python3
"""Wait for all Juju units in the model to be active/idle.

Uses the jubilant library for type-safe, structured Juju status polling.

Usage (called by wait_idle_jubilant() in helpers.sh):
    python3 wait_idle.py [--timeout SECONDS] [--interval SECONDS]
                         [--allow-blocked APP1,APP2,...]

Exit codes:
    0  All units active/idle.
    1  Timed out.
"""

import argparse
import logging
import sys

import jubilant

logging.basicConfig(
    level=logging.INFO,
    format="%(message)s",
)
# Jubilant logs status changes to this logger at INFO level.
logging.getLogger("jubilant.wait").setLevel(logging.INFO)


def _build_ready(allowed: set[str]):
    """Return a ready callable for ``Juju.wait()``.

    Units belonging to apps in *allowed* may be ``blocked/idle`` instead of
    ``active/idle``.  All other units must be ``active/idle``.
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
                if app_name in allowed and ws == "blocked" and js == "idle":
                    continue
                return False
        return True

    return ready


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Wait for all Juju units to be active/idle."
    )
    parser.add_argument("--timeout", type=int, default=600)
    parser.add_argument("--interval", type=int, default=30)
    parser.add_argument("--allow-blocked", type=str, default="", dest="allow_blocked")
    args = parser.parse_args()

    allowed = {a.strip() for a in args.allow_blocked.split(",") if a.strip()}

    juju = jubilant.Juju()

    print(
        f"Waiting for all Juju units to be active/idle "
        f"(timeout={args.timeout}s, poll={args.interval}s)\u2026"
    )

    try:
        juju.wait(
            _build_ready(allowed),
            timeout=args.timeout,
            delay=args.interval,
        )
    except TimeoutError:
        print(f"Timed out after {args.timeout}s. Final status:")
        print(juju.cli("status"))
        sys.exit(1)

    print("All units active/idle.")
    print(juju.cli("status"))


if __name__ == "__main__":
    main()
