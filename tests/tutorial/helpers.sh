#!/bin/bash
# Shared helpers for Charmed Apache Kafka tutorial spread tests.
#
# Source this file at the top of every task execute/prepare block:
#   . "$SPREAD_PATH/tests/tutorial/helpers.sh"

# Spread SSHs in as root but does not always set HOME=/root, which causes the
# Juju client to fail looking up its config in $HOME/.local/share/juju.
export HOME=/root

# ---------------------------------------------------------------------------
# juju_deploy_retry – run a juju deploy command with DNS retry logic.
#
# Usage:
#   juju_deploy_retry <juju deploy args...>
#
# Retries up to 3 times with DNS checks between attempts.
# ---------------------------------------------------------------------------
juju_deploy_retry() {
    local max_attempts=3
    for attempt in $(seq 1 "$max_attempts"); do
        # Verify DNS before attempting deploy.
        for dns_try in 1 2 3 4 5; do
            getent hosts api.charmhub.io >/dev/null 2>&1 && break
            echo "  DNS check before deploy attempt $attempt failed (try $dns_try), waiting 10s..."
            # Restart systemd-resolved to recover from transient failures.
            sudo systemctl restart systemd-resolved 2>/dev/null || true
            sleep 10
        done

        if juju deploy "$@"; then
            return 0
        fi

        if [[ "$attempt" -lt "$max_attempts" ]]; then
            echo "  juju deploy failed (attempt $attempt/$max_attempts), retrying in 30s..."
            sudo systemctl restart systemd-resolved 2>/dev/null || true
            sleep 30
        fi
    done
    echo "  ERROR: juju deploy failed after $max_attempts attempts"
    return 1
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

    local elapsed=0
    echo "Waiting for all Juju units to be active/idle (timeout=${timeout}s, poll=${interval}s)…"

    while [[ "$elapsed" -lt "$timeout" ]]; do
        local not_ready
        local status_json
        # Grab status JSON once per iteration.
        status_json=$(juju status --format=json 2>/dev/null) || status_json=""

        if [[ -z "$status_json" ]]; then
            not_ready="error"
        else
            not_ready=$(echo "$status_json" | python3 -c '
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
') || not_ready="error"
        fi

        if [[ "$not_ready" == "0" ]]; then
            echo "All units active/idle after ${elapsed}s."
            juju status
            return 0
        fi

        # Auto-resolve units stuck in error state so hooks can be retried.
        if [[ -n "$status_json" ]]; then
            local errored_units
            errored_units=$(echo "$status_json" | python3 -c '
import json, sys
try:
    data = json.load(sys.stdin)
    for app_name, app in data.get("applications", {}).items():
        for unit_name, unit in app.get("units", {}).items():
            ws = unit.get("workload-status", {}).get("current", "")
            if ws == "error":
                print(unit_name)
except Exception:
    pass
') || true
            for unit in $errored_units; do
                echo "  Resolving errored unit: $unit"
                juju resolve "$unit" 2>/dev/null || true
            done
        fi

        echo "[${elapsed}s elapsed] ${not_ready} unit(s) not in active/idle – rechecking in ${interval}s…"
        sleep "$interval"
        elapsed=$(( elapsed + interval ))
    done

    echo "Timed out after ${timeout}s. Final status:"
    juju status
    return 1
}

# ---------------------------------------------------------------------------
# juju_wait_for_install – wait until all units of an app have been provisioned
# and their install hooks have run (agent is idle/executing, not allocating).
#
# Usage:
#   juju_wait_for_install <app_name> <expected_units> [--timeout SECONDS]
#
# This ensures machines are up and charm install hooks have completed before
# relation hooks (from integrate) fire.
# ---------------------------------------------------------------------------
juju_wait_for_install() {
    local app_name="$1"; shift
    local expected_units="$1"; shift
    local timeout=900
    local interval=20

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --timeout)  timeout="$2";  shift 2 ;;
            --interval) interval="$2"; shift 2 ;;
            *) echo "juju_wait_for_install: unknown option: $1" >&2; return 1 ;;
        esac
    done

    local elapsed=0
    echo "Waiting for $expected_units '$app_name' units to be provisioned (timeout=${timeout}s)…"

    while [[ "$elapsed" -lt "$timeout" ]]; do
        local status_json
        status_json=$(juju status --format=json 2>/dev/null) || status_json=""

        if [[ -n "$status_json" ]]; then
            local result
            result=$(echo "$status_json" | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    app = data.get('applications', {}).get('$app_name', {})
    units = app.get('units', {})
    n = len(units)
    if n < $expected_units:
        print(f'waiting-for-units:{n}/$expected_units')
    else:
        # Check that all units have at least reached idle agent state
        not_idle = 0
        for uname, unit in units.items():
            js = unit.get('juju-status', {}).get('current', '')
            if js not in ('idle', 'executing'):
                not_idle += 1
        if not_idle > 0:
            print(f'provisioning:{not_idle}')
        else:
            print('done')
except Exception as e:
    print(f'error:{e}')
") || result="error"

            if [[ "$result" == "done" ]]; then
                echo "All $expected_units '$app_name' units provisioned after ${elapsed}s."
                return 0
            fi
            echo "[${elapsed}s elapsed] $app_name: $result – rechecking in ${interval}s…"
        else
            echo "[${elapsed}s elapsed] could not get status – rechecking in ${interval}s…"
        fi

        sleep "$interval"
        elapsed=$(( elapsed + interval ))
    done

    echo "Timed out after ${timeout}s waiting for '$app_name' provisioning. Final status:"
    juju status
    return 1
}

# ---------------------------------------------------------------------------
# fix_snap_install – ensure the charmed-kafka snap is installed on every unit.
#
# Usage:
#   fix_snap_install <app_name> <num_units>
#
# Waits for any in-progress snap install to complete. If the snap still
# isn't installed, sideloads it from the pre-downloaded cache in
# /root/snap-cache/ (bypassing unreliable network inside LXD containers).
# After installation, ensures Juju storage directories exist.
# ---------------------------------------------------------------------------
fix_snap_install() {
    local app_name="$1"
    local num_units="$2"

    echo "Ensuring charmed-kafka snap on '$app_name' units…"

    # Locate pre-downloaded snap files.
    local snap_file assert_file
    snap_file=$(ls /root/snap-cache/charmed-kafka_*.snap 2>/dev/null | head -1)
    assert_file=$(ls /root/snap-cache/charmed-kafka_*.assert 2>/dev/null | head -1)
    if [[ -z "$snap_file" ]]; then
        echo "  WARNING: No pre-downloaded snap found in /root/snap-cache/. Will try online install."
    fi

    for i in $(seq 0 $(( num_units - 1 )) ); do
        local unit="${app_name}/${i}"

        # Wait for any pending snap install to finish (up to 120s).
        local waited=0
        while [[ "$waited" -lt 120 ]]; do
            local pending
            pending=$(juju ssh "$unit" "snap changes 2>/dev/null | grep -cE 'Doing.*charmed-kafka'" 2>/dev/null) || pending="0"
            pending=$(echo "$pending" | tr -d '[:space:]')
            [[ "$pending" == "0" ]] && break
            echo "  $unit: snap install in progress, waiting… (${waited}s)"
            sleep 15
            waited=$(( waited + 15 ))
        done

        # Check if snap is installed.
        local snap_ok
        snap_ok=$(juju ssh "$unit" "snap list charmed-kafka >/dev/null 2>&1 && echo yes || echo no" 2>/dev/null) || snap_ok="no"
        snap_ok=$(echo "$snap_ok" | tr -d '[:space:]')

        if [[ "$snap_ok" != "yes" ]]; then
            echo "  $unit: snap NOT installed. Sideloading…"

            # Abort any stuck/errored snap changes first.
            juju ssh "$unit" "sudo bash -c 'for cid in \$(snap changes 2>/dev/null | grep -E \"(Doing|Error).*charmed-kafka\" | awk \"{print \\\$1}\"); do snap abort \$cid 2>/dev/null || true; done'" 2>/dev/null || true
            sleep 3

            if [[ -n "$snap_file" && -n "$assert_file" ]]; then
                # Sideload from pre-downloaded cache.
                juju scp "$snap_file" "$unit":/tmp/charmed-kafka.snap 2>/dev/null || true
                juju scp "$assert_file" "$unit":/tmp/charmed-kafka.assert 2>/dev/null || true
                juju ssh "$unit" "sudo snap ack /tmp/charmed-kafka.assert 2>/dev/null; sudo snap install /tmp/charmed-kafka.snap" 2>&1 || {
                    echo "  Warning: sideload failed on $unit, retrying with online install…"
                    juju ssh "$unit" "sudo snap install charmed-kafka --channel=4/edge" 2>&1 || \
                        echo "  ERROR: snap install failed on $unit"
                }
            else
                # No cache; try online install directly.
                juju ssh "$unit" "sudo snap install charmed-kafka --channel=4/edge" 2>&1 || \
                    echo "  ERROR: snap install failed on $unit"
            fi
        else
            echo "  $unit: snap OK"
        fi

        # Ensure the storage directory exists regardless.
        local storage_loc
        storage_loc=$(juju storage -m admin/tutorial --format=json 2>/dev/null | python3 -c "
import json, sys
data = json.load(sys.stdin)
storages = data.get('storage', {})
for sid, info in storages.items():
    attachments = info.get('attachments', {}).get('units', {})
    if '$unit' in attachments:
        loc = attachments['$unit'].get('location', '')
        if loc:
            print(loc)
            break
" 2>/dev/null) || storage_loc=""
        if [[ -n "$storage_loc" ]]; then
            juju ssh "$unit" "sudo mkdir -p $storage_loc" 2>/dev/null || true
        fi
    done
}
