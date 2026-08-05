# GovEngine Cloud Collector

Public, versioned deployment artifacts for the read-only GovEngine cloud
collector. Customers deploy the collector inside their own AWS account, Azure
subscription, or GCP project; no cloud credential is stored in GovEngine.

## Release contents

- `azure-template.json` — Azure subscription deployment template.
- `deploy/cloud/gcp/*.tf` — GCP Terraform package.
- `cloud-collector-release.json` — signed image reference, source revision,
  artifact URLs, and checksums.
- The versioned AWS CloudFormation URL named by the release record.

Use an immutable `cloud-collector-v*` tag or its matching GitHub release. The
default branch may advance when a newer collector is released. These files are
generated and validated by GovEngine's signed release workflow; do not publish
manual replacements under an existing version.

## Security

Review the provider's permission screen before deployment. Never enter or
commit cloud access keys, service-account keys, client secrets, or customer
data in this repository.

## License

Apache License 2.0. See [LICENSE](LICENSE).
