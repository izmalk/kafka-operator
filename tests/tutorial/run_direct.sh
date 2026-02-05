#!/bin/bash
# Direct test runner - runs tutorial steps on host (faster than nested LXD)
# Use this for faster local testing

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "=== Tutorial Direct Test Runner ==="
echo ""
echo "This runs tutorial commands directly on your host machine."
echo "⚠️  WARNING: This will:"
echo "  - Initialize LXD on your system"
echo "  - Install Juju snap"
echo "  - Bootstrap a Juju controller"
echo "  - Deploy Kafka charms"
echo ""
read -p "Continue? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 1
fi

echo ""
echo "=== Step 1: Environment Setup ==="
echo ""

# Create Juju directory (required for strict snap confinement)
# Handle both regular terminal and snap-confined terminal (like VS Code)
REAL_HOME=$(getent passwd $(whoami) | cut -d: -f6)
mkdir -p "$REAL_HOME/.local/share/juju"
mkdir -p ~/.local/share/juju 2>/dev/null || true

# Export JUJU_DATA to point to the real home directory
# This is critical when running from snap-confined terminals (like VS Code)
export JUJU_DATA="$REAL_HOME/.local/share/juju"
echo "Juju directory: $JUJU_DATA"

# Extract and run Step 1 commands
python3 helpers/extract_commands.py docs/tutorial/environment.md > /tmp/step1_commands.sh

echo "Commands to execute:"
cat /tmp/step1_commands.sh
echo ""

bash -x /tmp/step1_commands.sh

# Verify Step 1
echo ""
echo "=== Verifying Step 1 ==="
echo "✓ Checking LXD..."
lxc list > /dev/null && echo "  LXD OK"

echo "✓ Checking Juju controller..."
juju controllers | grep overlord && echo "  Controller OK"

echo "✓ Checking Juju model..."
juju models | grep tutorial && echo "  Model OK"

echo ""
echo "=== ✓ Step 1 Complete! ==="
echo ""
read -p "Continue to Step 2 (Deploy Kafka)? (y/N) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Stopped. You can run Step 2 later with this script."
    exit 0
fi

echo ""
echo "=== Step 2: Deploy Kafka ==="
echo ""

# Extract and run Step 2 commands (filtering out interactive commands)
python3 helpers/extract_commands.py docs/tutorial/deploy.md > /tmp/step2_commands.sh

# Filter out commands we don't want to run
grep -v "watch -n" /tmp/step2_commands.sh | \
grep -v "^juju status$" | \
grep -v "^bootstrap_address=" | \
grep -v "^export BOOTSTRAP_SERVER=" | \
grep -v "^juju show-secret" | \
grep -v "^juju show-unit" | \
grep -v "^juju ssh" > /tmp/step2_filtered.sh || true

echo "Commands to execute:"
cat /tmp/step2_filtered.sh
echo ""

bash -x /tmp/step2_filtered.sh

echo ""
echo "Waiting for Kafka deployment to complete..."
helpers/juju_wait.sh 900

# Verify Step 2
echo ""
echo "=== Verifying Step 2 ==="
echo "✓ Checking Kafka deployment..."
juju status kafka --format=json | jq -e '.applications.kafka' && echo "  Kafka OK"

echo "✓ Checking KRaft deployment..."
juju status kraft --format=json | jq -e '.applications.kraft' && echo "  KRaft OK"

echo ""
echo "=== ✓ Step 2 Complete! ==="
echo ""
echo "Final status:"
juju status

echo ""
echo "=== All Tests Passed! ==="
echo ""
echo "To clean up:"
echo "  ./cleanup.sh"
