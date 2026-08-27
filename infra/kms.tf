# kms.tf
# KMS key, service identity, IAM binding, and the CMEK-encrypted Artifact
# Registry repository are now provisioned via the published private-registry
# module instead of declared inline here â€” see
# https://app.terraform.io/app/gcpcloudhub/registry/private/gcpcloudhub/cmek-registry/google
# Module source: https://github.com/bikram-singh/terraform-google-cmek-registry

module "registry" {
  # checkov:skip=CKV_TF_1:Private-registry module (app.terraform.io), version-pinned
  # via semver ("~> 1.0"), not a git-hosted source -- commit-hash pinning doesn't apply.
  source  = "app.terraform.io/gcpcloudhub/cmek-registry/google"
  version = "~> 1.0"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  labels      = var.labels
}
