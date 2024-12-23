# Charmed Kafka documentation

Charmed Kafka is an open-source operator that makes it easier to manage Apache Kafka, with built-in support for enterprise features. 

Apache Kafka is a free, open source software project by the Apache Software Foundation. Users can find out more at the [Kafka project page](https://kafka.apache.org).

Charmed Kafka is built on top of [Juju](https://juju.is/) and reliably simplifies the deployment, scaling, design, and management of [Apache Kafka](https://kafka.apache.org/) in production. Additionally, you can use the charm to manage your Kafka clusters with automation capabilities. It also offers replication, TLS, password rotation, easy-to-use application integration, and monitoring.
Charmed Kafka operates Apache Kafka on physical systems, Virtual Machines (VM), and a wide range of cloud and cloud-like environments, including AWS, Azure, OpenStack, and VMware. 

Charmed Kafka is a solution designed and developed to help ops teams and 
administrators automate Apache Kafka operations from [Day 0 to Day 2](https://codilime.com/blog/day-0-day-1-day-2-the-software-lifecycle-in-the-cloud-age/), across multiple cloud environments and platforms.

[note]
Canonical has also developed the [Charmed Kafka K8s operator](/t/charmed-kafka-k8s-documentation/10296) to support Kafka in Kubernetes environments.
[/note]

Charmed Kafka is developed and supported by [Canonical](https://canonical.com/), as part of its commitment to 
provide open-source, self-driving solutions, seamlessly integrated using the Operator Framework Juju. Please 
refer to [Charmhub](https://charmhub.io/), for more charmed operators that can be integrated by [Juju](https://juju.is/).

## In this documentation

| | |
|--|--|
|  [Tutorials](/t/charmed-kafka-tutorial-overview/10571)</br>  Get started - a hands-on introduction to using Charmed Kafka operator for new users </br> |  [How-to guides](/t/charmed-kafka-how-to-manage-units/10287) </br> Step-by-step guides covering key operations and common tasks |
| [Reference](https://charmhub.io/kafka/actions?channel=3/stable) </br> Technical information - specifications, APIs, architecture | [Explanation]() </br> Concepts - discussion and clarification of key topics  |

## Project and community

Charmed Kafka is a distribution of Apache Kafka. It’s an open-source project that welcomes community contributions, suggestions, fixes and constructive feedback.
- [Read our Code of Conduct](https://ubuntu.com/community/code-of-conduct)
- [Join the Discourse forum](/tag/kafka)
- [Contribute](https://github.com/canonical/kafka-operator/blob/main/CONTRIBUTING.md) and report [issues](https://github.com/canonical/kafka-operator/issues/new)
- Explore [Canonical Data Fabric solutions](https://canonical.com/data)
- [Contact us]([/t/13107) for all further questions

Apache®, Apache Kafka, Kafka®, and the Kafka logo are either registered trademarks or trademarks of the Apache Software Foundation in the United States and/or other countries.

## License

The Charmed Kafka Operator is free software, distributed under the Apache Software License, version 2.0. See [LICENSE](https://github.com/canonical/kafka-operator/blob/main/LICENSE) for more information.

# Contents

1. [Tutorial](tutorial)
  1. [1. Introduction](tutorial/t-overview.md)
  1. [2. Set up the environment](tutorial/t-setup-environment.md)
  1. [3. Deploy Kafka](tutorial/t-deploy.md)
  1. [4. Integrate with client applications](tutorial/t-relate-kafka.md)
  1. [5. Manage passwords](tutorial/t-manage-passwords.md)
  1. [6. Enable Encryption](tutorial/t-enable-encryption.md)
  1. [7. Cleanup your environment](tutorial/t-cleanup-environment.md)
1. [How To](how-to)
  1. [Deploy](how-to/h-deploy.md)
  1. [Deploy on AWS](how-to/h-deploy-aws.md)
  1. [Deploy on Azure](how-to/h-deploy-azure.md)
  1. [Manage units](how-to/h-manage-units.md)
  1. [Manage applications](how-to/h-manage-app.md)
  1. [Enable encryption](how-to/h-enable-encryption.md)
  1. [Upgrade](how-to/h-upgrade.md)
  1. [Enable Monitoring](how-to/h-enable-monitoring.md)
  1. [Integrate alerts and dashboards](how-to/h-integrate-alerts-dashboards.md)
  1. [Migrate a cluster](how-to/h-cluster-migration.md)
  1. [Create mTLS Client Credentials](how-to/h-create-mtls-client-credentials.md)
  1. [Enable Oauth through Hydra](how-to/h-enable-oauth.md)
  1. [Backup and restore configuration](how-to/h-backup-restore-configuration.md)
  1. [Set up KRaft mode](how-to/h-kraft-mode.md)
1. [Reference](reference)
  1. [Release Notes](reference/r-releases)
    1. [Revision 156/126](reference/r-releases/r-rev156_126.md)
    1. [Revision 156/136](reference/r-releases/r-rev156_136.md)
  1. [File System Paths](reference/r-file-system-paths.md)
  1. [Snap Entrypoints](reference/r-snap-entrypoints.md)
  1. [Kafka Listeners](reference/r-listeners.md)
  1. [Statuses](reference/r-statuses.md)
  1. [Requirements](reference/r-requirements.md)
  1. [Performance Tuning](reference/r-performance-tuning.md)
  1. [Contact](reference/r-contacts.md)
1. [Explanation](explanation)
  1. [Security](explanation/e-security.md)
  1. [Hardening Guide](explanation/e-hardening.md)
  1. [Overview of Cluster Configuration](explanation/e-cluster-configuration.md)