#!/bin/bash
# Cleanup script for tutorial test resources

echo "=== Tutorial Test Cleanup ==="
echo ""

# Kill any running spread processes
echo "Stopping any running spread processes..."
pkill -f spread || true

sleep 2

# Cleanup Juju resources
echo "Cleaning up Juju resources..."
juju destroy-model tutorial --destroy-storage --force --no-wait -y 2>/dev/null || true
juju destroy-controller overlord --destroy-storage --force --no-wait -y 2>/dev/null || true

sleep 5

# Cleanup LXD containers
echo "Removing LXD containers..."

# Remove Juju containers
lxc list --format=json 2>/dev/null | jq -r '.[].name' | grep -E 'juju-' | while read container; do
    echo "  Removing $container..."
    lxc delete "$container" --force 2>/dev/null || true
done

# Remove spread containers
lxc list --format=json 2>/dev/null | jq -r '.[].name' | grep -E 'spread-' | while read container; do
    echo "  Removing $container..."
    lxc delete "$container" --force 2>/dev/null || true
done

echo ""
echo "✓ Cleanup complete!"
echo ""
echo "Remaining containers:"
lxc list
