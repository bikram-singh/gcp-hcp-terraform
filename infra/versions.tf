# versions.tf
# HCP Terraform (formerly Terraform Cloud) backend config.
#
# Uses workspace TAGS instead of a fixed workspace name, because this repo
# is shared by TWO workspaces (gcphub-dev-cloudrun and gcphub-prod-cloudrun).
# Both workspaces must be tagged "gcp-hcp-terraform" in the HCP Terraform UI
# for this block to resolve correctly. See SETUP.md Step 3.

terraform {
  cloud {
    organization = "gcpcloudhub" # your HCP Terraform org name (create in Step 1)

    workspaces {
      tags = ["gcp-hcp-terraform"]
    }
  }

  required_version = ">= 1.7.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}
