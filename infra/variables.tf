# variables.tf
# Values for these come from HCP Terraform Variable Sets (Phase 4), one set
# per environment ("gcphub-dev-vars", "gcphub-prod-vars"), attached to the
# matching workspace. Nothing here is hardcoded per environment.

variable "project_id" {
  description = "GCP project ID (gcphub-dev or gcphub-prod)"
  type        = string
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "asia-south1"
}

variable "environment" {
  description = "Environment name: dev or prod"
  type        = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either \"dev\" or \"prod\"."
  }
}

variable "allow_public" {
  description = "If true, allows unauthenticated (public) invocation of the Cloud Run service. Guarded by OPA policy in prod — see Phase 7."
  type        = bool
  default     = false
}

variable "min_instances" {
  description = "Cloud Run minimum instance count. Dev variable set = 0, prod variable set = 1 (enforced further by OPA mandatory policy)."
  type        = number
  default     = 0
}

variable "container_image" {
  description = "Full image path to deploy. Defaults to a public hello-world image for the first apply; switch to your Artifact Registry image once you push one (see SETUP.md Step 6)."
  type        = string
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "vpc_cidr" {
  description = "CIDR range for the subnet"
  type        = string
  default     = "10.10.0.0/24"
}

variable "labels" {
  description = "Common resource labels, org-standard tagging"
  type        = map(string)
  default = {
    org     = "gcpcloudhub"
    owner   = "bikram"
    managed = "hcp-terraform"
  }
}
