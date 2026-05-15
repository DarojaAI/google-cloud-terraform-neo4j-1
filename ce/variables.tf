##########################################
####### Required by Marketplace
##########################################

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "zone" {
  description = "GCP zone for deployment"
  type        = string
  default     = "us-central1-b"
}

variable "goog_cm_deployment_name" {
  description = "Deployment name"
  type        = string
}

variable "password" {
  description = "Neo4j password"
  type        = string
  sensitive   = true
}

variable "machine_type" {
  description = "GCP machine type"
  type        = string
  default     = "e2-medium"
}

variable "disk_size" {
  description = "Boot disk size in GB"
  type        = number
  default     = 100
}

variable "source_image" {
  description = "Source image for the VM"
  type        = string
  default     = "rocky-linux-cloud/rocky-linux-9"
}

variable "labels" {
  description = "Labels to apply to resources"
  type        = map(string)
  default     = {}
}

variable "assign_external_ip" {
  description = "Assign an external IP to the VM"
  type        = bool
  default     = false
}

variable "subnet_id" {
  description = "Subnet ID for custom VPC"
  type        = string
  default     = ""
}

variable "network_id" {
  description = "Network ID for custom VPC"
  type        = string
  default     = ""
}

variable "subnet_cidr" {
  description = "Subnet CIDR for firewall rules"
  type        = string
  default     = ""
}

variable "enable_vpc" {
  description = "Enable custom VPC mode. When true, uses subnet_id/network_id for VPC networking. When false, uses default network."
  type        = bool
  default     = false
}