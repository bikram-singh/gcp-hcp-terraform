# outputs.tf

output "cloud_run_url" {
  description = "Public/internal URL of the deployed Cloud Run service"
  value       = google_cloud_run_v2_service.service.uri
}

output "artifact_registry_repo" {
  description = "Artifact Registry repo path for pushing images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.repo.repository_id}"
}

output "vpc_name" {
  value = google_compute_network.vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.subnet.name
}

output "cloud_run_service_account" {
  value = google_service_account.cloud_run_sa.email
}
