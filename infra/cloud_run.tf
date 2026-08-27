# cloud_run.tf
# Cloud Run service, runtime IAM, and the health-check block are now
# provisioned via the published private-registry module instead of declared
# inline here. Module source:
# https://github.com/bikram-singh/terraform-google-cloud-run-service

module "cloud_run" {
  # checkov:skip=CKV_TF_1:Private-registry module (app.terraform.io), version-pinned
  # via semver ("~> 1.0"), not a git-hosted source -- commit-hash pinning doesn't apply.
  source  = "app.terraform.io/gcpcloudhub/cloud-run-service/google"
  version = "~> 1.0"

  project_id      = var.project_id
  region          = var.region
  environment     = var.environment
  labels          = var.labels
  container_image = var.container_image
  min_instances   = var.min_instances
  allow_public    = var.allow_public
  network_id      = module.network.vpc_id
  subnet_id       = module.network.subnet_id

  depends_on = [module.registry]
}
