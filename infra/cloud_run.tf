# cloud_run.tf

resource "google_cloud_run_v2_service" "service" {
  project  = var.project_id
  name     = "gcphub-${var.environment}-run-svc01"
  location = var.region
  labels   = var.labels

  template {
    service_account = google_service_account.cloud_run_sa.email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.environment == "prod" ? 10 : 3
    }

    containers {
      image = var.container_image

      resources {
        limits = {
          cpu    = "1"
          memory = "512Mi"
        }
      }
    }

    vpc_access {
      network_interfaces {
        network    = google_compute_network.vpc.id
        subnetwork = google_compute_subnetwork.subnet.id
      }
      egress = "PRIVATE_RANGES_ONLY"
    }
  }

  depends_on = [google_artifact_registry_repository.repo]
}

# Continuous validation check (Phase 16) — asserts the service has a URL
# assigned post-apply. HCP Terraform re-evaluates this on a schedule
# independent of the next plan/apply.
check "cloud_run_healthy" {
  data "google_cloud_run_v2_service" "service_check" {
    project  = var.project_id
    location = var.region
    name     = google_cloud_run_v2_service.service.name
  }

  assert {
    condition     = data.google_cloud_run_v2_service.service_check.uri != ""
    error_message = "Cloud Run service ${google_cloud_run_v2_service.service.name} has no assigned URL."
  }
}
