# Copilot Instructions for Charmed Apache Kafka Operator

This guide enables AI coding agents to be productive in this codebase by summarizing key architecture, workflows, and conventions.

## Architecture Overview
- **Operator Structure**: Implements a Juju charm for Apache Kafka, automating deployment, scaling, and management.
- **Major Components**:
  - `src/`: Charm logic, event handlers, core models, workload management, alert rules, and integration managers.
  - `lib/`: Shared libraries for interfaces (certificates, data platform, etc.) and Kafka-specific logic.
  - `docs/`: Sphinx-based documentation, including how-to guides, explanations, and references.
- **Service Boundaries**: Follows Juju's model of applications, relations, and actions. Kafka is managed as controllers and brokers, with integration points for TLS, monitoring, and data clients.

## Developer Workflows
- **Build**: Use `charmcraft` for building and packaging the charm. See `charmcraft.yaml` for configuration.
- **Test**: Run unit and integration tests in `tests/unit/` and `tests/integration/` using `tox` or directly with `pytest`. `tox.ini` configures environments.
- **Deploy**: Use Juju commands for deployment and integration (see README for examples).
- **Debug**: Use `juju status`, `juju ssh`, and charm actions for troubleshooting. Logs are available via Juju and on units.

## Project-Specific Patterns
- **Secure-by-default**: Listeners are disabled unless related to another application. Use `data-integrator` to enable listeners for testing.
- **Rolling Operations**: Scaling and restarts are performed in a rolling fashion to maintain cluster health.
- **Secrets Management**: Passwords and sensitive data are managed via Juju secrets and config (`juju add-secret`, `juju grant-secret`, `juju config`).
- **Storage**: Storage volumes are managed via Juju, with logs stored at `/var/snap/kafka/common`.
- **Relations**: Integrations are handled via Juju relations (e.g., `kafka_client`, `tls-certificates`).
- **Monitoring**: Metrics exposed via JMX exporter and integrated with Grafana Agent and COS Lite.

## Integration Points & External Dependencies
- **Juju**: All deployment, scaling, and integration is managed via Juju CLI and charms.
- **Charmcraft**: Used for building and packaging the charm.
- **Snap**: Kafka binaries and admin commands are provided via the `charmed-kafka` snap.
- **TLS**: Managed via `tls-certificates-operator` charm and Juju relations.
- **Monitoring**: Integrates with Prometheus/Grafana via JMX exporter and Grafana Agent.

## Key Files & Directories
- `src/charm.py`: Main charm entry point.
- `src/core/`, `src/events/`, `src/managers/`: Core logic, event handling, and management.
- `lib/`: Interface and shared libraries.
- `tests/`: Unit and integration tests.
- `docs/`: Documentation and guides.
- `charmcraft.yaml`, `tox.ini`, `config.yaml`, `metadata.yaml`: Build, test, and charm configuration.

## Example Commands
- Build: `charmcraft pack`
- Test: `tox` or `pytest tests/unit/`
- Deploy: `juju deploy kafka -n 5 --config roles="controller" controller`
- Integrate: `juju integrate kafka:peer-cluster-orchestrator controller:peer-cluster`
- Scale: `juju add-unit kafka -n 2`
- Rotate password: `juju add-secret mysecret admin=My$trongP4ss`

## Conventions
- Follow Juju charm patterns for event handling and relations.
- Use Sphinx for documentation in `docs/`.
- Store sensitive data in Juju secrets, not in code or config files.
- Prefer rolling operations for cluster changes.

---
If any section is unclear or missing, please provide feedback to improve these instructions.
