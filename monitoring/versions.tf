terraform {
  cloud {
    organization = "gcpcloudhub"

    workspaces {
      name = "gcphub-dev-monitoring"
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
