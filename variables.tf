variable "project_id" {
  description = "The GCP project ID where the resources will be deployed."
  type        = string
}

variable "region" {
  description = "The GCP region where the resources will be deployed."
  type        = string
}

variable "vpc_name" {
  description = "The name of the VPC to be created."
  type        = string
}

variable "webapp_subnet_name" {
  description = "The name of the webapp subnet."
  type        = string
}

variable "db_subnet_name" {
  description = "The name of the db subnet."
  type        = string
}

variable "webapp_subnet_cidr" {
  description = "CIDR block for the webapp subnet."
  type        = string
}

variable "db_subnet_cidr" {
  description = "CIDR block for the db subnet."
  type        = string
}

variable "webapp_route_name" {
  description = "The name of the route for internet access from the webapp subnet."
  type        = string
}