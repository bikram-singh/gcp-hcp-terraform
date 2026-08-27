# network.tf
# VPC, subnet, and internal firewall are now provisioned via the published
# private-registry module instead of declared inline here — see
# https://app.terraform.io/app/gcpcloudhub/registry/modules/private/gcpcloudhub/vpc-subnet/google
# Module source: https://github.com/bikram-singh/terraform-google-vpc-subnet

module "network" {
  # checkov:skip=CKV_TF_1:This is a private-registry module (app.terraform.io),
  # not a git-hosted source — it's version-pinned via semver ("~> 1.0"), which
  # is the correct pinning mechanism for registry modules. Commit-hash pinning
  # only applies to git-source modules and doesn't apply here.
  source  = "app.terraform.io/gcpcloudhub/vpc-subnet/google"
  version = "~> 1.0"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  labels      = var.labels
}
