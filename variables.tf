variable "project_id" {
  type        = string
  description = "The ID of the Google Cloud project"
}

variable "region" {
  type        = string
  description = "The region where resources will be created"
}

variable "vpc_name" {
  type        = string
  description = "The name of the VPC"
}

variable "webapp_name" {
  type        = string
  description = "The name of the web application"
}

variable "db_name" {
  type        = string
  description = "The name of the database"
}

variable "webapp_routename" {
  type        = string
  description = "The name of the route for the web application"
}

variable "webapp_subnet_cidr" {
  type        = string
  description = "The CIDR range for the web application subnet"
}

variable "db_subnet_cidr" {
  type        = string
  description = "The CIDR range for the database subnet"
}

variable "dest_range" {
  type        = string
  description = "The destination range for the firewall rule"
}

variable "firewall_name" {
  type        = string
  description = "The name of the firewall rule"
}

variable "app_protocol" {
  type        = string
  description = "The protocol for the application"
}

variable "app_ports" {
  type        = list(number)
  description = "The ports for the application"
}

variable "app_ports_ssh" {
  type        = list(number)
  description = "The SSH ports for the application"
}

variable "source_ranges" {
  type        = list(string)
  description = "The source IP ranges for the firewall rule"
}

variable "zone" {
  type        = string
  description = "The zone where resources will be created"
}

variable "instance_name" {
  type        = string
  description = "The name of the VM instance"
}

variable "machine_type" {
  type        = string
  description = "The machine type for the VM instance"
}

variable "instance_image" {
  type        = string
  description = "The image for the VM instance"
}

variable "boot_disk_type" {
  type        = string
  description = "The type of boot disk for the VM instance"
}

variable "disk_size_gb" {
  type        = number
  description = "The size of the boot disk for the VM instance"
}

variable "instance_network" {
  type        = string
  description = "The network for the VM instance"
}

variable "instance_subnet" {
  type        = string
  description = "The subnet for the VM instance"
}

variable "routing_mode" {
  type        = string
  description = "The routing mode for the network"
}

variable "database_name" {
  type        = string
  description = "The name of the database"
}

variable "user_name" {
  type        = string
  description = "The username for the database"
}


variable "topic_name" {
  description = "The name of the Pub/Sub topic for email verification"
  type        = string
  default     = "verify_email"
}

variable "duration" {
  description = "The duration in seconds for which emails should be retained"
  type        = string
}

variable "subscription_name" {
  description = "The name of the Pub/Sub subscription for email verification"
  type        = string

}

variable "bucket_name" {
  description = "The name of the Google Cloud Storage bucket"
  type        = string
}

variable "bucket_location" {
  description = "The location of the Google Cloud Storage bucket"
  type        = string
}
variable "domain_name" {
  type        = string
  description = "The domain name for the application"
}

variable "api_key" {
  type        = string
  description = "The API key for the application"
}

variable "router_name" {
  type        = string
  description = "The name of the router"
}

variable "nat_name" {
  type        = string
  description = "The name of the NAT gateway"
}

variable "port_no" {
  type        = number
  description = "The port number"
}


variable "max_replicas" {
  description = "Maximum number of replicas for autoscaling"
  type        = number
}

variable "min_replicas" {
  description = "Minimum number of replicas for autoscaling"
  type        = number
}

variable "cooldown_period" {
  description = "Cooldown period in seconds for autoscaling"
  type        = number
}

