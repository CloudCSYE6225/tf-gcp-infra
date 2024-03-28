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
    service_account {
    email  = google_service_account.webapp_service_account.email
    scopes = ["logging-write", "monitoring-write","https://www.googleapis.com/auth/pubsub"]
  }
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

resource "google_dns_record_set" "a_record" {
  name         = "deepaksundar.me."
  type         = "A"
  ttl          = 300
  managed_zone = "my-webapp-zone"
  rrdatas      = [google_compute_instance.vm_instance.network_interface[0].access_config[0].nat_ip]
}

resource "google_service_account" "webapp_service_account" {
  account_id   = "webapp"
  display_name = "Service Account for webapp insatnce"
  project      = var.project_id

}

resource "google_project_iam_binding" "logging_admin_iam_role" {
  project = var.project_id
  role    = "roles/logging.admin"
  members = [
    google_service_account.webapp_service_account.member,
  ]
}
resource "google_project_iam_binding" "monitoring_metric_writer_role" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"

  members = [
    google_service_account.webapp_service_account.member,
  ]
}
resource "google_project_iam_binding" "pubsub-publisher" {
  project = var.project_id
  role    = "roles/pubsub.publisher"

  members = [
    google_service_account.webapp_service_account.member,
  ]
}

resource "google_pubsub_topic" "verify_email" {
  name = var.topic_name
  message_retention_duration = var.duration
}

resource "google_pubsub_subscription" "verify_email_subscription" {
  name = var.subscription_name
  topic = google_pubsub_topic.verify_email.name

  ack_deadline_seconds = 20
}

resource "google_storage_bucket" "bucket" {
  name     = var.bucket_name
  location = var.bucket_location
}

resource "google_storage_bucket_object" "archive" {
  name   = "serverless.zip"
  bucket = google_storage_bucket.bucket.name
  source = "C:/Users/deepu/OneDrive/Documents/GitHub/serverless.zip"
}

resource "google_compute_router" "router" {
  project = var.project_id
  name = var.router_name
  region = var.region
  network = google_compute_network.vpc.name

  bgp{
    asn = 64514
  }

}

resource "google_compute_router_nat" "nat" {
  project = var.project_id
  name = var.nat_name
  router = google_compute_router.router.name
  region = var.region

  nat_ip_allocate_option = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"

  min_ports_per_vm = 64

  log_config {
    enable = true
    filter = "ALL"
  }
}

resource "google_vpc_access_connector" "serverless_connector" {
  provider = google-beta
  name = "serverless-connector"
  project = var.project_id
  region = var.region
  network = google_compute_network.vpc.name
  ip_cidr_range = "10.8.0.0/28"
  min_throughput = 200
  max_throughput = 300
}

resource "google_cloudfunctions2_function" "app" {
  name        = "sendVerificationEmail"
  location    = var.region
  description = "Function to send verification emails via Mailgun"

  build_config {
    runtime     = "nodejs20"
    entry_point = "sendVerificationEmail" # Set the entry point
    source {
      storage_source {
         bucket = google_storage_bucket.bucket.name
         object = google_storage_bucket_object.archive.name
      }
    }
  }

    service_config {
    environment_variables = {
     DOMAIN = var.domain_name,
     APIKEY = var.api_key,
     DB_HOST = google_sql_database_instance.cloudsql_instance.private_ip_address,
     DB_USER = var.user_name,
     DB_PASSWORD = random_password.password.result,
     DB_NAME = var.database_name,
     DB_PORT = var.port_no
    }
    service_account_email          = google_service_account.webapp_service_account.email
    vpc_connector                  = google_vpc_access_connector.serverless_connector.id
    vpc_connector_egress_settings  = "ALL_TRAFFIC" 

  }

    event_trigger {
    trigger_region = var.region
    event_type     = "google.cloud.pubsub.topic.v1.messagePublished"
    pubsub_topic   = google_pubsub_topic.verify_email.id
    retry_policy   = "RETRY_POLICY_RETRY"
  }
}

# resource "google_cloudfunctions_function" "app" {
#   name        = "sendVerificationEmail"
#   description = "Function to send verification emails via Mailgun"
#   runtime     = "nodejs20"
#   timeout = 540
#   available_memory_mb   = 128
#   source_archive_bucket = google_storage_bucket.bucket.name
#   source_archive_object = google_storage_bucket_object.archive.name
#   entry_point           = "serverless"
#   event_trigger {
#     event_type = "google.pubsub.topic.publish"
#     resource = google_pubsub_topic.verify_email.id
#     failure_policy {
#       retry = false
#     }
#   }

#   environment_variables = {
#     MAILGUN_DOMAIN = "deepaksundar.me",
#     MAILGUN_API_KEY = "8c6f1d9935cc28e3d0adf07ad72903b8-309b0ef4-a193e503"
#   }
# }