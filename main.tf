provider "google" {
  project = var.project_id
  region  = var.region
}

resource "google_compute_network" "vpc" {
  name                    = var.vpc_name
  auto_create_subnetworks = false
  routing_mode            = var.routing_mode
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

resource "google_compute_firewall" "allow_application_traffic" {
  name    = "allow-application-traffic"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["3000","80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["webapp-vm"]
}

resource "google_compute_firewall" "allow_ssh_from_internal" {
  name    = "allow-ssh-from-internal"
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]

  target_tags = ["webapp-vm"]
}

resource "google_compute_instance" "vm_instance" {
  name         = var.name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image # Replace with your custom image self-link
      type  = var.type
      size  = var.size
    }
  }

  network_interface {
    network    = google_compute_network.vpc.id
    subnetwork = google_compute_subnetwork.webapp.id

    access_config {
      // Ephemeral external IP will be assigned
    }
  }

  tags = ["webapp-vm"]

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  metadata_startup_script = "sudo systemctl enable csye6225.service && sudo systemctl start csye6225.service"
}

output "instance_ip" {
  value = google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip
}
