provider "google" {
  project     = var.project_id
  region      = var.region
}

resource "random_pet" "vpc_name_suffix" {
  length = 2
}

resource "google_compute_network" "vpc" {
  name                            = var.vpc_name
  auto_create_subnetworks         = false
  routing_mode                    = var.routing_mode
  delete_default_routes_on_create = true
}

resource "google_compute_subnetwork" "webapp" {
  name          = var.webapp_name
  ip_cidr_range = var.webapp_subnet_cidr
  network       = google_compute_network.vpc.self_link
  region        = var.region
}

resource "google_compute_subnetwork" "db" {
  name          = var.db_name
  ip_cidr_range = var.db_subnet_cidr
  network       = google_compute_network.vpc.self_link
  region        = var.region
}

resource "google_compute_global_address" "private_services_access_ip_range"{
  provider     = google-beta
  project      = var.project_id
  name         = "global-psconnect-ip"
  address_type = "INTERNAL"
  purpose      = "VPC_PEERING" 
  network      = google_compute_network.vpc.self_link
  prefix_length = 16
}

resource "google_compute_route" "webapp-route" {
  name             = var.webapp_routename
  network          = google_compute_network.vpc.self_link
  dest_range       = var.dest_range
  priority         = 1000
  next_hop_gateway = "default-internet-gateway"
}


resource "google_service_networking_connection" "default" {
  network                 = google_compute_network.vpc.self_link
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.private_services_access_ip_range.name]
}
 
resource "google_compute_firewall" "allow_app_traffic" {
  name    = var.firewall_name
  network = google_compute_network.vpc.name

  allow {
    protocol = var.app_protocol
    ports    = var.app_ports
  }
  source_ranges = var.source_ranges
}


resource "google_compute_instance" "vm_instance" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["http-server"]
  boot_disk {
    initialize_params {
      image = var.instance_image
      size  = var.disk_size_gb
      type  = var.boot_disk_type
    }
  }

  network_interface {
     network    = google_compute_network.vpc.name
     subnetwork = var.instance_subnet
    access_config {
      // Ephemeral IP assigned here
    }
  }
  metadata_startup_script = <<-SCRIPT
    # Ensure /opt/webapp directory exists
    mkdir -p /opt/webapp

    echo "working 1"

    CLOUD_SQL_PRIVATE_IP=$(gcloud sql instances describe ${google_sql_database_instance.cloudsql_instance.name} --format="get(ipAddresses[?type=PRIVATE].ipAddress)")
    echo "working 2"
    # Write the .env file
    echo "MYSQL_USER=${google_sql_user.webapp_user.name}" > /opt/webapp/.env
    echo "MYSQL_PASSWORD=${random_password.password.result}" >> /opt/webapp/.env
    echo "MYSQL_HOST=${google_sql_database_instance.cloudsql_instance.private_ip_address}" >> /opt/webapp/.env
    echo "MYSQL_PORT=3306" >> /opt/webapp/.env
    echo "MYSQL_DATABASE=${google_sql_database.webapp.name}" >> /opt/webapp/.env
    echo "working 3"

    # Enable and start the csye6225.service 
    sudo systemctl daemon-reload
    sudo systemctl restart csye6225.service
    sudo systemctl enable csye6225.service
    echo "working 4"
  SCRIPT
}

resource "google_sql_database_instance" "cloudsql_instance" {
  provider = google-beta

  name                = "instance"
  project             = var.project_id
  region              = var.region
  database_version    = "MYSQL_8_0"
  deletion_protection = false
  depends_on = [google_service_networking_connection.default]  
  settings {
    tier                        = "db-custom-1-3840"
    activation_policy           = "ALWAYS"
    availability_type           = "REGIONAL"
    disk_size                   = 100
    disk_type                   = "pd-ssd"
    ip_configuration {
      ipv4_enabled              = false
      private_network           = google_compute_network.vpc.id
    }
    backup_configuration {
      enabled = true
      binary_log_enabled = true 
    }
  }

}

resource "google_sql_database" "webapp"{
  name = var.database_name
  instance = google_sql_database_instance.cloudsql_instance.name
}

resource "random_password" "password" {
  length  = 16
  special = false
}

resource "google_sql_user" "webapp_user" {
  name     = var.user_name
  instance = google_sql_database_instance.cloudsql_instance.name
  password = random_password.password.result
}