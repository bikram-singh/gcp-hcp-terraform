variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "cloud_run_url" {
  description = "Full HTTPS URL of the Cloud Run service to monitor (from gcphub-dev's cloud_run_url output)"
  type        = string
}

variable "notification_email" {
  description = "Email address to notify on uptime check failure"
  type        = string
}

variable "check_interval_seconds" {
  description = "How often to run the uptime check"
  type        = string
  default     = "300s"
}
