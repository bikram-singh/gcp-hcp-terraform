# outputs.tf

output "cloud_run_url" {
  description = "Public/internal URL of the deployed Cloud Run service"
  value       = module.cloud_run.cloud_run_url
}

output "artifact_registry_repo" {
  description = "Artifact Registry repo path for pushing images"
  value       = module.registry.repository_url
}

output "vpc_name" {
  value = module.network.vpc_name
}

output "subnet_name" {
  value = module.network.subnet_name
}

output "cloud_run_service_account" {
  value = module.cloud_run.service_account_email
}
