# artifact_registry.tf

resource "google_artifact_registry_repository" "repo" {
  project       = var.project_id
  location      = var.region
  repository_id = "gcphub-${var.environment}-repo"
  description   = "Container images for gcp-hcp-terraform Cloud Run service (${var.environment})"
  format        = "DOCKER"
  labels        = var.labels
}
