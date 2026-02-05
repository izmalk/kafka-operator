#!/bin/bash
# Quick test script to run tutorial tests

set -e

cd "$(dirname "$0")"

echo "=== Tutorial Test Runner ==="
echo ""
echo "This script runs the tutorial tests in order."
echo "Each test extracts commands from the markdown files and executes them."
echo ""

# Check prerequisites
echo "Checking prerequisites..."
command -v lxd >/dev/null 2>&1 || { echo "ERROR: lxd not found. Install with: sudo snap install lxd"; exit 1; }
command -v ~/go/bin/spread >/dev/null 2>&1 || { echo "ERROR: spread not found. Install with: go install github.com/snapcore/spread/cmd/spread@latest"; exit 1; }

echo "✓ Prerequisites OK"
echo ""

# Run tests
echo "Running Tutorial Step 1: Environment Setup"
echo "This will take 20-30 minutes as it sets up LXD and Juju (increased timeout for nested LXD)..."
echo ""
~/go/bin/spread -v lxd:ubuntu-24.04:tutorial/01-environment

if [ $? -eq 0 ]; then
    echo ""
    echo "✓ Step 1 passed! Running Step 2..."
    echo ""
    echo "Running Tutorial Step 2: Deploy Kafka"
    echo "This will take 15-20 minutes as it deploys Kafka clusters..."
    ~/go/bin/spread -v -reuse lxd:ubuntu-24.04:tutorial/02-deploy
fi

echo ""
echo "=== All tests completed successfully! ==="
echo ""
echo "To clean up:"
echo "  ~/go/bin/spread -discard"
echo "  or run: ./cleanup.sh"
