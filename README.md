# tf-gcp-infra
## Terraform Google Cloud Platform VPC Configuration
This Terraform configuration creates a Virtual Private Cloud (VPC) on Google Cloud Platform (GCP) with two subnetworks (webapp and db) and a route for the webapp subnet to allow internet access.


## Prerequisites
Before running this Terraform configuration, make sure you have:

Installed Terraform.
Configured your Google Cloud Platform authentication credentials.

## Command used
terraform init
terraform plan
terraform apply


## Inputs
project_id: The ID of the Google Cloud Platform project.
region: The region where the VPC and subnetworks will be created.
vpc_name: The name of the VPC.
webapp_subnet_name: The name of the webapp subnet.
webapp_subnet_cidr: The CIDR range for the webapp subnet.
db_subnet_name: The name of the db subnet.
db_subnet_cidr: The CIDR range for the db subnet.
