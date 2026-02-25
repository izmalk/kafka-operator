#!/bin/bash
# Shared helpers for Charmed Apache Kafka tutorial spread tests.
#
# Source this file at the top of every task execute/prepare block:
#   . "$SPREAD_PATH/tests/tutorial/helpers.sh"

# ---------------------------------------------------------------------------
# Timing – wall-clock elapsed time since the test suite started.
# ---------------------------------------------------------------------------

# Initialised on first source; exported so every child shell inherits the
# same origin, giving a consistent clock across all sourced scripts.
export SUITE_START=${SUITE_START:-$SECONDS}

# elapsed() – print time since SUITE_START as XmYYs (e.g. 2m05s).
elapsed() {
    local secs=$(( SECONDS - SUITE_START ))
    printf '%dm%02ds' $(( secs / 60 )) $(( secs % 60 ))
}

# _log MSG
# Write a timestamped progress line.  Spread captures stdout/stderr from
# remote scripts and only surfaces them with -debug, so we also write to
# /dev/tty when it is available (local scripts running with a real tty).
_log() {
    printf '%s\n' "$*" >&2
    printf '%s\n' "$*" > /dev/tty 2>/dev/null || true
}

# run_cmd CMD [ARGS…]
# Log a command with its elapsed-time prefix, run it, then log the exit code.
run_cmd() {
    _log "[$(elapsed)] $ $*"
    "$@"
    local rc=$?
    _log "[$(elapsed)] ^ exit ${rc}"
    return $rc
}

# enable_cmd_trace
# Install a DEBUG trap so every command executed in the calling script is
# logged with an elapsed-time prefix.  Call once near the top of a test
# script after sourcing helpers.sh.
enable_cmd_trace() {
    export SUITE_START
    trap 'printf "\n[%s] $ %s\n" "$(elapsed)" "$BASH_COMMAND" >&2' DEBUG
}

# ---------------------------------------------------------------------------
# juju_wait – poll until every Juju unit in the model is active/idle.
#
# Usage:
#   juju_wait [--timeout SECONDS] [--interval SECONDS]
#
# Defaults:
#   --timeout  600   (10 minutes)
#   --interval  30   (check every 30 seconds)
#
# Returns 0 when all units are active/idle, 1 on timeout.
# ---------------------------------------------------------------------------
juju_wait() {
    local timeout=600
    local interval=30

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --timeout)  timeout="$2";  shift 2 ;;
            --interval) interval="$2"; shift 2 ;;
            *) echo "juju_wait: unknown option: $1" >&2; return 1 ;;
        esac
    done

    local waited=0
    echo "Waiting for all Juju units to be active/idle (timeout=${timeout}s, poll=${interval}s)…"

    while [[ "$waited" -lt "$timeout" ]]; do
        local not_ready
        not_ready=$(
            juju status --format=json 2>/dev/null | python3 - <<'PYEOF'
import json, sys
try:
    data = json.load(sys.stdin)
    not_ready = 0
    for app in data.get("applications", {}).values():
        for unit in app.get("units", {}).values():
            ws = unit.get("workload-status", {}).get("current", "")
            js = unit.get("juju-status",    {}).get("current", "")
            if ws != "active" or js != "idle":
                not_ready += 1
    print(not_ready)
except Exception:
    print("error")
PYEOF
        )

        if [[ "$not_ready" == "0" ]]; then
            echo "All units active/idle after ${waited}s."
            juju status
            return 0
        fi

        echo "[$(elapsed) / ${waited}s into wait] ${not_ready} unit(s) not in active/idle – rechecking in ${interval}s…"
        sleep "$interval"
        waited=$(( waited + interval ))
    done

    echo "Timed out after ${timeout}s. Final status:"
    juju status
    return 1
}
