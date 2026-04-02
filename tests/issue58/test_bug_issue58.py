#!/usr/bin/env python3
"""
Bug reproduction for https://github.com/canonical/kafka-connect-operator/issues/58

Verifies whether the reported bug exists:
1. When PluginDownloadFailedError is raised in _on_integration_requested,
   the event is NOT deferred (bare return) -- credentials are never set.
2. Subsequent collect-status hooks do NOT re-trigger _on_integration_requested.
3. Even though update_plugins() in reconcile() may retry plugin downloads
   on subsequent hooks, update_clients_data() SKIPS clients without passwords.
4. Subsequent relation-changed events do NOT re-emit IntegrationRequestedEvent
   because the diff() function already recorded plugin-url as "old data".

The hypothesis under test: "collect-status hook handlers are called after every
hook, which means eventually, if the plugin download issue is transient, it
will succeed on subsequent hooks, and we don't need to defer."
"""

import dataclasses
import json
import logging
import warnings
from typing import cast
from unittest.mock import MagicMock

import pytest
from charms.data_platform_libs.v0.data_interfaces import (
    IntegrationRequestedEvent,
)
from ops.testing import Context, PeerRelation, Relation, State

from src.charm import ConnectCharm
from src.literals import CLIENT_REL, PEER_REL, Status
from managers.connect import PluginDownloadFailedError

# Suppress warnings inherited from upstream charm libraries (not related to this test)
pytestmark = pytest.mark.filterwarnings(
    "ignore::DeprecationWarning",
    "ignore::pytest.PytestConfigWarning",
)

logger = logging.getLogger(__name__)


# ---------------------------------------------------------------------------
# TEST 1: Bare return on PluginDownloadFailedError -- event NOT deferred,
#          credentials NOT set
# ---------------------------------------------------------------------------
def test_plugin_download_failure_drops_event_no_defer(
    ctx: Context, base_state: State, active_service: MagicMock
) -> None:
    """Verify that when PluginDownloadFailedError is raised, the event is
    not deferred (bare return), and credentials are never set on the
    connect-client relation.
    """
    relation_id = 7
    plugin_url = "http://10.10.10.10:8080/plugin.tar"

    client_rel = Relation(
        CLIENT_REL,
        CLIENT_REL,
        id=relation_id,
        remote_app_data={"plugin-url": plugin_url},
    )
    peer_rel = PeerRelation(PEER_REL, PEER_REL)
    event = IntegrationRequestedEvent(
        handle=MagicMock(),
        relation=client_rel,  # pyright: ignore[reportArgumentType]
    )

    state_in = dataclasses.replace(base_state, relations=[peer_rel, client_rel])

    connect_manager_mock = MagicMock()
    connect_manager_mock.load_plugin_from_url.side_effect = PluginDownloadFailedError(
        "Connection refused"
    )
    auth_manager_mock = MagicMock()

    with ctx(ctx.on.update_status(), state_in) as mgr:
        charm = cast(ConnectCharm, mgr.charm)
        charm.connect_manager = connect_manager_mock
        charm.auth_manager = auth_manager_mock

        charm.connect.provider._on_integration_requested(event)
        state_out = mgr.run()

    client_rel_out = state_out.get_relation(client_rel.id)

    # Credentials were not set (bare return skipped set_credentials/set_endpoints)
    assert client_rel_out.local_app_data.get("username") is None, (
        "Expected username to be None when plugin download fails"
    )
    assert client_rel_out.local_app_data.get("password") is None, (
        "Expected password to be None when plugin download fails"
    )
    # auth_manager.update was never called
    assert auth_manager_mock.update.call_count == 0, (
        "Expected auth_manager.update not to be called on the error path"
    )


# ---------------------------------------------------------------------------
# TEST 2: collect-status does NOT retry plugin download or set credentials
# ---------------------------------------------------------------------------
def test_collect_status_does_not_retry_integration(
    ctx: Context, base_state: State, active_service: MagicMock
) -> None:
    """Verify that collect-status does not retry plugin downloads or set credentials.

    Tests the hypothesis that collect-status hooks provide a recovery path.
    """
    relation_id = 7
    plugin_url = "http://10.10.10.10:8080/plugin.tar"

    client_rel = Relation(
        CLIENT_REL,
        CLIENT_REL,
        id=relation_id,
        remote_app_data={"plugin-url": plugin_url},
    )
    peer_rel = PeerRelation(PEER_REL, PEER_REL)
    state_in = dataclasses.replace(base_state, relations=[peer_rel, client_rel])

    connect_manager_mock = MagicMock()
    auth_manager_mock = MagicMock()

    with ctx(ctx.on.collect_unit_status(), state_in) as mgr:
        charm = cast(ConnectCharm, mgr.charm)
        charm.connect_manager = connect_manager_mock
        charm.auth_manager = auth_manager_mock
        state_out = mgr.run()

    assert connect_manager_mock.load_plugin_from_url.call_count == 0, (
        "collect-status should not call load_plugin_from_url"
    )
    client_rel_out = state_out.get_relation(client_rel.id)
    assert client_rel_out.local_app_data.get("username") is None, (
        "collect-status should not set credentials on the relation"
    )


# ---------------------------------------------------------------------------
# TEST 3: update_plugins() retries downloads but cannot set credentials
# ---------------------------------------------------------------------------
def test_update_plugins_retry_cannot_set_credentials(
    ctx: Context, base_state: State, active_service: MagicMock
) -> None:
    """Even if update_plugins() eventually downloads the plugin successfully,
    update_clients_data() SKIPS clients without passwords."""
    relation_id = 7
    plugin_url = "http://10.10.10.10:8080/plugin.tar"

    client_rel = Relation(
        CLIENT_REL,
        CLIENT_REL,
        id=relation_id,
        remote_app_data={"plugin-url": plugin_url},
    )
    peer_rel = PeerRelation(PEER_REL, PEER_REL)
    state_in = dataclasses.replace(base_state, relations=[peer_rel, client_rel])

    connect_manager_mock = MagicMock()
    connect_manager_mock.load_plugin_from_url.return_value = None
    connect_manager_mock.loaded_client_plugins = []
    auth_manager_mock = MagicMock()

    with ctx(ctx.on.update_status(), state_in) as mgr:
        charm = cast(ConnectCharm, mgr.charm)
        charm.connect_manager = connect_manager_mock
        charm.auth_manager = auth_manager_mock
        state_out = mgr.run()

    # Plugin download was retried via update_plugins()
    assert connect_manager_mock.load_plugin_from_url.call_count >= 1, (
        "update_plugins() should retry the plugin download"
    )

    # However, credentials were still not set
    client_rel_out = state_out.get_relation(client_rel.id)
    assert client_rel_out.local_app_data.get("username") is None, (
        "Credentials should remain unset -- only _on_integration_requested can set them"
    )
    assert client_rel_out.local_app_data.get("password") is None, (
        "Password should remain None -- update_clients_data() skips clients without passwords"
    )


# ---------------------------------------------------------------------------
# TEST 4: Subsequent relation-changed does NOT re-emit IntegrationRequestedEvent
#          because diff() already recorded plugin-url
# ---------------------------------------------------------------------------
def test_subsequent_relation_changed_does_not_re_emit_integration_requested(
    ctx: Context, base_state: State, active_service: MagicMock
) -> None:
    """After the first relation-changed event, the diff() function records
    plugin-url as "old data". Subsequent relation-changed events will NOT
    have plugin-url in diff.added, so IntegrationRequestedEvent is NOT
    re-emitted.

    This proves the event is truly a one-shot: once the first relation-changed
    event fires and diff() runs, the data is recorded and future events
    won't re-trigger IntegrationRequestedEvent.
    """
    relation_id = 7
    plugin_url = "http://10.10.10.10:8080/plugin.tar"

    # Simulate post-bug state: the diff() has already stored plugin-url
    # in the "data" field of local_app_data (this happens after first
    # relation-changed event processes through the library's diff() function)
    already_seen_data = json.dumps({"plugin-url": plugin_url})

    client_rel = Relation(
        CLIENT_REL,
        CLIENT_REL,
        id=relation_id,
        remote_app_data={"plugin-url": plugin_url},
        # The "data" field records what the library's diff() has already seen
        local_app_data={"data": already_seen_data},
    )
    peer_rel = PeerRelation(PEER_REL, PEER_REL)
    state_in = dataclasses.replace(base_state, relations=[peer_rel, client_rel])

    connect_manager_mock = MagicMock()
    # Make plugin download succeed now (transient failure resolved)
    connect_manager_mock.load_plugin_from_url.return_value = None
    connect_manager_mock.loaded_client_plugins = []
    auth_manager_mock = MagicMock()

    with ctx(ctx.on.relation_changed(client_rel), state_in) as mgr:
        charm = cast(ConnectCharm, mgr.charm)
        charm.connect_manager = connect_manager_mock
        charm.auth_manager = auth_manager_mock

        # Track whether _on_integration_requested was called
        original_handler = charm.connect.provider._on_integration_requested
        integration_requested_called = []

        def tracking_handler(event):
            integration_requested_called.append(True)
            original_handler(event)

        charm.connect.provider._on_integration_requested = tracking_handler

        state_out = mgr.run()

    # IntegrationRequestedEvent should not be re-emitted because diff()
    # already recorded plugin-url as old data
    assert len(integration_requested_called) == 0, (
        "IntegrationRequestedEvent should not be re-emitted on subsequent "
        "relation-changed because diff() already recorded plugin-url."
    )

    # Credentials are still not set
    client_rel_out = state_out.get_relation(client_rel.id)
    assert client_rel_out.local_app_data.get("username") is None or \
           client_rel_out.local_app_data.get("username") == client_rel.local_app_data.get("username"), (
        "No new credentials should be set by subsequent relation-changed"
    )


# ---------------------------------------------------------------------------
# TEST 5 (control): Normal flow works when plugin download succeeds
# ---------------------------------------------------------------------------
def test_successful_plugin_download_sets_credentials(
    ctx: Context, base_state: State, active_service: MagicMock
) -> None:
    """Control test: when plugin download succeeds, credentials ARE set."""
    relation_id = 7
    plugin_url = "http://10.10.10.10:8080/plugin.tar"

    client_rel = Relation(
        CLIENT_REL,
        CLIENT_REL,
        id=relation_id,
        remote_app_data={"plugin-url": plugin_url},
    )
    peer_rel = PeerRelation(PEER_REL, PEER_REL)
    event = IntegrationRequestedEvent(
        handle=MagicMock(),
        relation=client_rel,  # pyright: ignore[reportArgumentType]
    )

    state_in = dataclasses.replace(base_state, relations=[peer_rel, client_rel])
    connect_manager_mock = MagicMock()
    auth_manager_mock = MagicMock()

    with ctx(ctx.on.update_status(), state_in) as mgr:
        charm = cast(ConnectCharm, mgr.charm)
        charm.connect_manager = connect_manager_mock
        charm.auth_manager = auth_manager_mock

        charm.connect.provider._on_integration_requested(event)
        state_out = mgr.run()

    client_rel_out = state_out.get_relation(client_rel.id)
    assert client_rel_out.local_app_data.get("username") == f"relation-{relation_id}", (
        "Username should be set when plugin download succeeds"
    )
    assert client_rel_out.local_app_data.get("password") is not None, (
        "Password should be set when plugin download succeeds"
    )
    assert auth_manager_mock.update.call_count == 1, (
        "auth_manager.update should be called on the success path"
    )
