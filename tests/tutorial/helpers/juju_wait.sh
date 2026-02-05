#!/bin/bash
# Wait for Juju to reach a stable state with all units active/idle

set -e

TIMEOUT=${1:-900}  # Default 15 minutes
INTERVAL=10
ELAPSED=0

echo "Waiting for Juju status to stabilize (timeout: ${TIMEOUT}s)..."

while [ $ELAPSED -lt $TIMEOUT ]; do
    # Get juju status in JSON format
    STATUS_JSON=$(juju status --format=json 2>/dev/null || echo '{}')
    
    # Check if we have any applications
    APP_COUNT=$(echo "$STATUS_JSON" | jq '.applications | length' 2>/dev/null || echo "0")
    
    if [ "$APP_COUNT" -eq "0" ]; then
        echo "No applications deployed yet, waiting..."
        sleep $INTERVAL
        ELAPSED=$((ELAPSED + INTERVAL))
        continue
    fi
    
    # Check for any units not in active/idle state
    NOT_READY=$(echo "$STATUS_JSON" | jq -r '
        .applications | to_entries[] | 
        .value.units // {} | to_entries[] | 
        select(
            (.value."workload-status".current != "active") or 
            (.value."agent-status".current != "idle")
        ) | 
        .key
    ' 2>/dev/null || echo "")
    
    # Check for any applications not in active state
    APP_NOT_READY=$(echo "$STATUS_JSON" | jq -r '
        .applications | to_entries[] | 
        select(.value.status.current != "active") | 
        .key
    ' 2>/dev/null || echo "")
    
    if [ -z "$NOT_READY" ] && [ -z "$APP_NOT_READY" ]; then
        echo "✓ All units are active/idle"
        juju status
        return 0
    fi
    
    echo "Waiting for units to become active/idle... (${ELAPSED}s elapsed)"
    if [ -n "$NOT_READY" ]; then
        echo "  Units not ready: $NOT_READY"
    fi
    if [ -n "$APP_NOT_READY" ]; then
        echo "  Apps not ready: $APP_NOT_READY"
    fi
    
    sleep $INTERVAL
    ELAPSED=$((ELAPSED + INTERVAL))
done

echo "ERROR: Timeout waiting for Juju to stabilize after ${TIMEOUT}s"
juju status
exit 1
