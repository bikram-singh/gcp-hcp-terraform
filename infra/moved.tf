# moved.tf
# Maps the root-level resources that used to live directly in network.tf to
# their new addresses inside module.network, published as a private-registry
# module (terraform-google-vpc-subnet). Without these blocks, Terraform would
# plan to DESTROY the old resources and CREATE new ones under the module —
# these blocks tell it they're the same resources, just renamed, so the
# existing live VPC/subnet/firewall in dev and prod are preserved untouched.

moved {
  from = google_compute_network.vpc
  to   = module.network.google_compute_network.vpc
}

moved {
  from = google_compute_subnetwork.subnet
  to   = module.network.google_compute_subnetwork.subnet
}

moved {
  from = google_compute_firewall.allow_internal
  to   = module.network.google_compute_firewall.allow_internal
}

# --- CMEK/Artifact Registry module migration (terraform-google-cmek-registry) ---
# Same safety pattern: without these, Terraform would destroy the live KMS
# key, service identity, IAM binding, and Artifact Registry repo and recreate
# them under module.registry. The KMS key additionally has
# lifecycle { prevent_destroy = true }, which would have hard-failed the
# apply outright if this mapping were missing or wrong — an extra safety net
# on top of the moved block itself.

moved {
  from = google_kms_key_ring.repo_keyring
  to   = module.registry.google_kms_key_ring.repo_keyring
}

moved {
  from = google_kms_crypto_key.repo_key
  to   = module.registry.google_kms_crypto_key.repo_key
}

moved {
  from = google_project_service_identity.artifact_registry_sa
  to   = module.registry.google_project_service_identity.artifact_registry_sa
}

moved {
  from = google_kms_crypto_key_iam_member.ar_service_agent
  to   = module.registry.google_kms_crypto_key_iam_member.ar_service_agent
}

moved {
  from = google_artifact_registry_repository.repo
  to   = module.registry.google_artifact_registry_repository.repo
}
