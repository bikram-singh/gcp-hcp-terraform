# kms.tf
# KMS key, service identity, IAM binding, and the CMEK-encrypted Artifact
# Registry repository are now provisioned via the published private-registry
# module instead of declared inline here — see
# https://app.terraform.io/app/gcpcloudhub/registry/private/gcpcloudhub/cmek-registry/google
# Module source: https://github.com/bikram-singh/terraform-google-cmek-registry

module "registry" {
  source  = "app.terraform.io/gcpcloudhub/cmek-registry/google"
  version = "~> 1.0"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  labels      = var.labels
}
