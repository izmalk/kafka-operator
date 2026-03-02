#!/bin/bash
# Extracted from : docs/tutorial/deploy.md
# Regenerate with: python3 tests/tutorial/extract_commands.py docs/tutorial/deploy.md <output.sh>
#
# To skip a block in the Markdown source, add this comment on the line
# immediately before its opening fence (blank lines are fine between them):
#   <!-- test:skip -->
#
# Only ```shell fences are extracted; use any other tag to naturally exclude a block.

set -euo pipefail

# shellcheck source=tests/tutorial/helpers.sh
. "$SPREAD_PATH/tests/tutorial/helpers.sh"

juju_deploy_retry kafka -n 3 --channel 4/edge --config roles=broker

# The tutorial says to wait until brokers reach "blocked" status
# (waiting for KRaft controller). This ensures snaps are installed
# before relation hooks fire.
juju_wait_for_install kafka 3 --timeout 900

# Give the charm's install hook time to attempt snap install (may fail due to
# the storage-mount race condition). We'll fix it in the next step.
sleep 60

# Fix snap installation if Juju storage mount prevented it.
fix_snap_install kafka 3

juju_deploy_retry kafka -n 3 --channel 4/edge --config roles=controller kraft

# Wait for controller snap installation to finish too.
juju_wait_for_install kraft 3 --timeout 900

# Same delay for kraft units.
sleep 60

# Fix snap installation on controller units too.
fix_snap_install kraft 3

juju integrate kafka:peer-cluster-orchestrator kraft:peer-cluster

# Wait for all 6 units (3 brokers + 3 controllers) to reach active/idle.
juju_wait --timeout 1800

juju show-secret --reveal cluster.kafka.app

juju show-secret --reveal cluster.kafka.app | yq -r '.[].content["operator-password"]'

bootstrap_address=$(juju show-unit kafka/0 | yq '.. | ."public-address"? // ""' | tr -d '"' | tr -d '\r\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

export BOOTSTRAP_SERVER="${bootstrap_address}:19093"

juju ssh kafka/leader sudo -i "ls \$BIN/bin"

juju ssh kafka/0 sudo -i \
    "charmed-kafka.topics \
        --create \
        --topic test-topic \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --command-config \$CONF/client.properties"

juju ssh kafka/0 sudo -i \
    "charmed-kafka.topics \
        --list \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --command-config \$CONF/client.properties"

juju ssh kafka/0 sudo -i \
    "charmed-kafka.topics \
        --delete \
        --topic test-topic \
        --bootstrap-server $BOOTSTRAP_SERVER \
        --command-config \$CONF/client.properties"
