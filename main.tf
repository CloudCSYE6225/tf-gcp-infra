provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
  delete_default_routes_on_create = true

}

resource "google_compute_subnetwork" "webapp" {
  name          = var.webapp_subnet_name
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.webapp_subnet_cidr
}

resource "google_compute_subnetwork" "db" {
  name          = var.db_subnet_name
  region        = var.region
  network       = google_compute_network.vpc.id
  ip_cidr_range = var.db_subnet_cidr
}

resource "google_compute_route" "webapp_internet" {
  name             = "webapp-internet-route"
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.id
  next_hop_gateway = "default-internet-gateway"
}