#!/bin/bash
# ============================================================================
# Reproduction script for:
#   https://github.com/canonical/kafka-connect-operator/issues/58
#
# "Integrator permanently blocked: _on_integration_requested does not defer
#  on PluginDownloadFailedError"
#
# This script clones the kafka-connect-operator repo, installs dependencies,
# copies in the reproduction tests, and runs them.
#
# Requirements: Ubuntu 22.04+ with Python 3.10+, git, pip
# ============================================================================

set -euo pipefail

WORKDIR="${1:-/tmp/issue58-repro}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=============================================="
echo "Issue #58 Bug Reproduction"
echo "=============================================="
echo ""
echo "Working directory: $WORKDIR"
echo ""

# ---------------------------------------------------------------------------
# 1. Clone the repo
# ---------------------------------------------------------------------------
if [ -d "$WORKDIR/kafka-connect-operator" ]; then
    echo "[1/4] Repo already cloned, pulling latest..."
    cd "$WORKDIR/kafka-connect-operator"
    git pull --quiet 2>/dev/null || true
else
    echo "[1/4] Cloning kafka-connect-operator..."
    mkdir -p "$WORKDIR"
    git clone --depth 1 https://github.com/canonical/kafka-connect-operator.git \
        "$WORKDIR/kafka-connect-operator"
    cd "$WORKDIR/kafka-connect-operator"
fi

# ---------------------------------------------------------------------------
# 2. Set up virtual environment and install dependencies
# ---------------------------------------------------------------------------
echo "[2/4] Setting up Python venv and installing dependencies..."
if [ ! -d ".venv" ]; then
    python3 -m virtualenv .venv
fi
source .venv/bin/activate

pip install -q \
    "ops[testing]>=2.17.0" \
    pytest \
    pyyaml \
    tenacity \
    pure-sasl \
    jsonschema \
    "pydantic<2" \
    requests \
    cosl \
    lightkube \
    cryptography \
    poetry-core

pip install -q -e "git+https://github.com/canonical/kafkacl@main#egg=kafkacl"

echo "  Dependencies installed."

# ---------------------------------------------------------------------------
# 3. Copy test file into the repo's test directory
# ---------------------------------------------------------------------------
echo "[3/4] Copying reproduction test..."
cp "$SCRIPT_DIR/test_bug_issue58.py" \
   "$WORKDIR/kafka-connect-operator/tests/unit/test_bug_issue58.py"

# ---------------------------------------------------------------------------
# 4. Run the tests
# ---------------------------------------------------------------------------
echo "[4/4] Running 5 bug reproduction tests..."
echo ""

PYTHONPATH=lib:src:. pytest tests/unit/test_bug_issue58.py -v --tb=short \
    -W ignore::DeprecationWarning -W 'ignore::pytest.PytestConfigWarning'

echo ""
echo "=============================================="
echo "SUMMARY"
echo "=============================================="
echo ""
echo "All 5 tests pass, confirming the reported bug exists."
echo ""
echo "What each test shows:"
echo ""
echo "  Test 1: PluginDownloadFailedError -> bare 'return' -> credentials"
echo "          never set on the connect-client relation. Event is not deferred."
echo ""
echo "  Test 2: collect-status does NOT retry plugin downloads or set"
echo "          credentials. It only collects unit/app status."
echo ""
echo "  Test 3: update_plugins() (via reconcile on config-changed) DOES retry"
echo "          plugin downloads, but update_clients_data() explicitly SKIPS"
echo "          clients without passwords. Since only _on_integration_requested"
echo "          can call set_credentials(), credentials remain permanently absent."
echo ""
echo "  Test 4: IntegrationRequestedEvent is effectively one-shot. After the"
echo "          first relation-changed event, the data_interfaces library's"
echo "          diff() function records plugin-url as 'old data'. Subsequent"
echo "          relation-changed events will NOT re-emit the event."
echo ""
echo "  Test 5: Control test -- when plugin download succeeds, credentials"
echo "          ARE set correctly. Confirms the bug is in the error path only."
echo ""
echo "Suggested fix: In src/events/provider.py:_on_integration_requested, replace:"
echo "       except PluginDownloadFailedError as e:"
echo "           logger.error(f'Unable to fetch the plugin: {e}')"
echo "           return  # <-- event lost"
echo "  With:"
echo "       except PluginDownloadFailedError as e:"
echo "           logger.error(f'Unable to fetch the plugin: {e}')"
echo "           logger.error(f'Unable to fetch the plugin: {e}')"
echo "           event.defer()  # <-- FIX: retry on next hook cycle"
echo "           return"
