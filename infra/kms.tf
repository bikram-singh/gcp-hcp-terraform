# kms.tf
# Customer-managed encryption key (CMEK) for Artifact Registry — fixes
# Checkov CKV_GCP_84. Uses Cloud KMS instead of Google-managed default keys.

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

# Artifact Registry's Google-managed service agent doesn't exist by default
# until explicitly provisioned — this creates it declaratively instead of
# assuming it already exists (that assumption caused a failed apply once).
resource "google_project_service_identity" "artifact_registry_sa" {
  provider = google-beta
  project  = var.project_id
  service  = "artifactregistry.googleapis.com"
}

# The service agent then needs permission to use this key for encrypt/decrypt.
# Without this binding, pushes/pulls to the repo fail.
resource "google_kms_crypto_key_iam_member" "ar_service_agent" {
  crypto_key_id = google_kms_crypto_key.repo_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member        = google_project_service_identity.artifact_registry_sa.member
}
