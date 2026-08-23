# network.tf

resource "google_compute_network" "vpc" {
  project                 = var.project_id
  name                     = "gcphub-${var.environment}-vpc01"
  auto_create_subnetworks  = false
  routing_mode             = "REGIONAL"
}

resource "google_compute_subnetwork" "subnet" {
  project                  = var.project_id
  name                     = "gcphub-${var.environment}-subnet01"
  ip_cidr_range            = var.vpc_cidr
  region                   = var.region
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true # lets resources reach Google APIs without public IPs
}

# Allows internal traffic within the subnet (adjust/narrow further if you add more services)
resource "google_compute_firewall" "allow_internal" {
  project = var.project_id
  name    = "gcphub-${var.environment}-allow-internal"
  network = google_compute_network.vpc.id

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }
  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  source_ranges = [var.vpc_cidr]
}
