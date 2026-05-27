---
myst:
  html_meta:
    description: "Complete documentation for Charmed Apache Kafka operator - deploy, manage, and scale Charmed Apache Kafka clusters on VMs, AWS, Azure, and OpenStack."
---

(index)=

```{note}
This is an **IAAS/VM** charmed operator.
To deploy on Kubernetes, see [Charmed Apache Kafka K8s operator](https://documentation.ubuntu.com/charmed-kafka-k8s/4/).
```

(charmed-apache-kafka)=
# Charmed Apache Kafka documentation

**Charmed Apache Kafka is an open-source operator, packaged as a [Juju charm](https://documentation.ubuntu.com/juju/3.6/reference/charm/), that deploys and manages [Apache Kafka](https://kafka.apache.org) clusters on physical hardware, virtual machines, and cloud environments including AWS, Azure, and OpenStack.**

**The charm automates Apache Kafka operations from Day 0 to Day 2.** It handles cluster deployment and scaling, TLS encryption, password rotation, client credential management, monitoring integration, partition rebalancing with Cruise Control, and cross-cluster replication with MirrorMaker 2.

**This documentation covers setup, configuration, security, and maintenance of Charmed Apache Kafka clusters.** It includes a guided tutorial, task-oriented how-to guides for each supported platform, reference material for system internals, and explanations of architectural decisions.

**The documentation is intended for ops teams and system administrators who manage Apache Kafka clusters using Juju.** It assumes familiarity with Linux system administration and the Juju deployment model.

## In this documentation

The following sections organise pages by subject rather than by documentation type, so that all resources for a given topic appear together.

### Getting started

The tutorial provides a guided path from first deployment through to advanced topics such as encryption and ETL.

* **Tutorial**: {ref}`Introduction <tutorial-introduction>` • {ref}`Environment setup <tutorial-environment>` • {ref}`Deploy <tutorial-deploy>` • {ref}`Client integration <tutorial-integrate-with-client-applications>` • {ref}`Password management <tutorial-manage-passwords>` • {ref}`Encryption <tutorial-enable-encryption>` • {ref}`Kafka Connect ETL <tutorial-kafka-connect>` • {ref}`Partition rebalancing <tutorial-rebalance-partitions>` • {ref}`Cleanup <tutorial-cleanup>`

### Deployment

All deployment methods produce equivalent clusters; the choice depends on your target platform and infrastructure tooling.

* **Juju CLI**: {ref}`Deploy with Juju <how-to-deploy-anywhere>`
* **Terraform**: {ref}`Deploy via Terraform <how-to-deploy-terraform>` • {ref}`Terraform module reference <reference-terraform>`
* **AWS**: {ref}`Deploy on AWS <how-to-deploy-on-aws>`
* **Azure**: {ref}`Deploy on Azure <how-to-deploy-on-azure>`
* **Network spaces**: {ref}`Deploy on Juju spaces <how-to-deploy-spaces>`
* **Requirements**: {ref}`System requirements <reference-requirements>`
* **Release notes**: {ref}`Releases <reference-release-notes-index>`

### Security and encryption

Internal communication between brokers and controllers is encrypted by default; client-facing encryption and authentication require additional configuration.

* **TLS**: {ref}`Enable TLS encryption <how-to-tls-encryption>` • {ref}`Enable encryption (tutorial) <tutorial-enable-encryption>` • {ref}`Cryptography details <explanation-cryptography>`
* **mTLS**: {ref}`Create mTLS client credentials <how-to-create-mtls-client-credentials>`
* **OAuth**: {ref}`Enable OAuth <how-to-enable-oauth>`
* **Security overview**: {ref}`Security <explanation-security>`

### Client applications and data streaming

Clients connect to Charmed Apache Kafka through the Data Integrator charm; Kafka Connect and Karapace extend the cluster for ETL and schema management.

* **Client connections**: {ref}`Manage client connections <how-to-client-connections>` • {ref}`Client integration (tutorial) <tutorial-integrate-with-client-applications>`
* **Kafka Connect**: {ref}`Use Kafka Connect for ETL <how-to-use-kafka-connect-for-etl-workloads>` • {ref}`Kafka Connect ETL (tutorial) <tutorial-kafka-connect>`
* **Schemas**: {ref}`Schemas and serialisation <how-to-schemas-serialisation>`
* **Kafka UI**: {ref}`Use Kafka UI <how-to-kafka-ui>`
* **Listeners**: {ref}`Broker listeners <reference-broker-listeners>`

### Operations and maintenance

Cruise Control enables partition rebalancing when brokers are added or removed; the Canonical Observability Stack provides metrics, alerts, and dashboards.

* **Unit management**: {ref}`Manage units <how-to-manage-units>` • {ref}`Partition rebalancing (tutorial) <tutorial-rebalance-partitions>`
* **Monitoring**: {ref}`Set up monitoring <how-to-monitoring>`
* **Upgrades**: {ref}`Upgrade between versions <how-to-upgrade>`
* **Replication**: {ref}`Set up cluster replication <how-to-cluster-replication>` • {ref}`MirrorMaker 2.0 overview <explanation-mirrormaker2-0>`
* **Migration**: {ref}`Migrate from non-charmed clusters <how-to-cluster-migration>`
* **Backups**: {ref}`Backups <explanation-backups>`
* **Performance**: {ref}`Performance tuning <reference-performance-tuning>`
* **Passwords**: {ref}`Password management (tutorial) <tutorial-manage-passwords>`
* **Internals**: {ref}`Snap commands <reference-snap-commands>` • {ref}`File system paths <reference-file-system-paths>` • {ref}`Charm statuses <reference-statuses>`

## How this documentation is organised

This documentation uses the [Diátaxis documentation structure](https://diataxis.fr/).

* {ref}`Tutorials <tutorial-introduction>` take you from a fresh environment through deployment, client integration, encryption, ETL with Kafka Connect, and partition rebalancing.
* {ref}`How-to guides <how-to-index>` cover deploying on AWS, Azure, and bare metal, configuring TLS and OAuth, managing client connections, scaling units, and setting up monitoring with the Canonical Observability Stack.
* {ref}`Reference <reference-index>` lists system requirements, file system paths, snap commands, listener configuration, charm statuses, and Terraform module inputs.
* {ref}`Explanation <explanation-index>` discusses the security model, cryptographic implementation, backup strategy, and MirrorMaker 2.0 architecture.

## Project and community

Charmed Apache Kafka is part of the [Juju](https://juju.is/) ecosystem and integrates with other charms in the [Canonical Data Platform](https://canonical.com/data).

### Get involved

Report bugs and request features through the project issue tracker on GitHub. Discuss the charm and share operational experience with other users and contributors.

* [Matrix channel](https://matrix.to/#/#charmhub-data-platform:ubuntu.com)
* [Discourse forum](https://discourse.charmhub.io/tag/kafka)
* [Issue tracker](https://github.com/canonical/kafka-operator/issues/new)
* [Contribution guide](https://github.com/canonical/kafka-operator/blob/main/CONTRIBUTING.md)
* {ref}`Contacts <reference-contact>`

### Governance and policies

* [Code of conduct](https://ubuntu.com/community/code-of-conduct)
* {ref}`Trademarks <explanation-trademarks>`

### Commercial support

For enterprise deployment assistance and commercial support, explore [Canonical Data solutions](https://canonical.com/data).

```{toctree}
:titlesonly:
:maxdepth: 2
:hidden:

Home <self>
tutorial/index
how-to/index
reference/index
explanation/index
```
