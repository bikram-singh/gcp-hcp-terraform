# kms.tf
# Customer-managed encryption key (CMEK) for Artifact Registry — fixes
# Checkov CKV_GCP_84. Uses Cloud KMS instead of Google-managed default keys.

data "google_project" "current" {
  project_id = var.project_id
}

resource "google_kms_key_ring" "repo_keyring" {
  project  = var.project_id
  name     = "gcphub-${var.environment}-keyring"
  location = var.region
}

resource "google_kms_crypto_key" "repo_key" {
  name     = "gcphub-${var.environment}-ar-key"
  key_ring = google_kms_key_ring.repo_keyring.id

  # Rotate automatically every 90 days — standard org practice.
  rotation_period = "7776000s"

  lifecycle {
    prevent_destroy = true # never allow accidental key deletion
  }
}

# Artifact Registry's own Google-managed service agent needs permission to
# use this key for encrypt/decrypt. Without this binding, pushes/pulls fail.
resource "google_kms_crypto_key_iam_member" "ar_service_agent" {
  crypto_key_id = google_kms_crypto_key.repo_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-artifactregistry.iam.gserviceaccount.com"
}
