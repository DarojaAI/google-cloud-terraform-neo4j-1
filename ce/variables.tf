##########################################
####### Required by Marketplace
##########################################

variable "project_id" {
  description = "The GCP project ID where resources will be created"
  type        = string
}

variable "goog_cm_deployment_name" {
  description = "The name of the deployment and VM instance."
  type        = string
}

variable "source_image" {
  description = "Base image for the VM instance."
  type        = string
  default     = "projects/neo4j-mp-public/global/images/neo4j-community-edition-v20260126"
}

##########################################
####### Deployment Specific Variables
##########################################

variable "zone" {
  description = "The GCP zone where resources will be created"
  type        = string
}

variable "password" {
  description = "Password for Neo4j"
  type        = string
  sensitive   = true
}

variable "machine_type" {
  description = "GCP machine type for Neo4j nodes"
  type        = string
  default     = "n4-standard-4"
}

variable "disk_size" {
  description = "Size of the data disk in GB"
  type        = number
  default     = 100
}

##########################################
####### VPC Configuration (Optional)
##########################################

variable "subnet_id" {
  description = "Subnet ID (name) for VM placement. If provided, deploys to custom VPC instead of default."
  type        = string
  default     = ""
}

variable "network_id" {
  description = "VPC network ID (self-link) for firewall rules. Required when subnet_id is set."
  type        = string
  default     = ""
}

variable "assign_external_ip" {
  description = "Assign external IP. If false, VM is private and uses Cloud NAT for egress."
  type        = bool
  default     = true
}

variable "labels" {
  description = "Labels to apply to all resources"
  type        = map(string)
  default     = {}
}