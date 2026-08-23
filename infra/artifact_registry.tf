# artifact_registry.tf

resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "gcphub-${var.environment}-repo"
  description   = "Container images for gcp-hcp-terraform Cloud Run service (${var.environment})"
  format        = "DOCKER"
  labels        = var.labels

  # CMEK encryption — see kms.tf. Must depend on the IAM binding so the
  # service agent can actually use the key before the repo tries to.
  kms_key_name = google_kms_crypto_key.repo_key.id

  depends_on = [google_kms_crypto_key_iam_member.ar_service_agent]
}
