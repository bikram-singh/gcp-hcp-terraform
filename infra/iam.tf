# iam.tf
# Least-privilege runtime identity for the Cloud Run service itself.
# NOTE: this is separate from the WIF service account HCP Terraform uses to
# deploy — that one is created once via gcloud, see SETUP.md Step 2.

resource "google_service_account" "cloud_run_sa" {
  project      = var.project_id
  account_id   = "gcphub-${var.environment}-run-sa"
  display_name = "Cloud Run runtime SA (${var.environment})"
}

# Only what Cloud Run's runtime actually needs — nothing broader.
resource "google_project_iam_member" "run_sa_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

resource "google_project_iam_member" "run_sa_metrics" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cloud_run_sa.email}"
}

# Public invocation is OFF by default (var.allow_public = false).
# Only created when explicitly enabled — this is the resource an OPA
# mandatory policy in prod should block outright (Phase 7 / 20.5).
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count    = var.allow_public ? 1 : 0
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.service.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
