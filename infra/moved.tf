# moved.tf
# Maps the root-level resources that used to live directly in network.tf to
# their new addresses inside module.network, published as a private-registry
# module (terraform-google-vpc-subnet). Without these blocks, Terraform would
# plan to DESTROY the old resources and CREATE new ones under the module —
# these blocks tell it they're the same resources, just renamed, so the
# existing live VPC/subnet/firewall in dev and prod are preserved untouched.

moved {
  from = google_compute_network.vpc
  to   = module.network.google_compute_network.vpc
}

moved {
  from = google_compute_subnetwork.subnet
  to   = module.network.google_compute_subnetwork.subnet
}

moved {
  from = google_compute_firewall.allow_internal
  to   = module.network.google_compute_firewall.allow_internal
}
