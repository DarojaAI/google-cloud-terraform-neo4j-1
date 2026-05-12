provider "google" {
  project = var.project_id
}

locals {
  use_custom_vpc = var.subnet_id != "" && var.network_id != ""
}

##########################################
####### Static Internal IP (VPC mode)
##########################################

resource "google_compute_address" "neo4j_internal" {
  count        = local.use_custom_vpc ? 1 : 0
  name         = "${var.goog_cm_deployment_name}-internal-ip"
  address_type = "INTERNAL"
  subnetwork   = var.subnet_id
  region       = substr(var.zone, 0, length(var.zone) - 2)

  labels = var.labels
}

##########################################
####### Neo4j Compute Instance
##########################################

resource "google_compute_instance" "neo4j" {
  name         = "${var.goog_cm_deployment_name}-instance"
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.source_image
      size  = var.disk_size
      type  = "pd-ssd"
    }
  }

  network_interface {
    # Custom VPC mode: use subnet with optional static internal IP
    subnetwork = local.use_custom_vpc ? var.subnet_id : null
    network_ip = local.use_custom_vpc ? google_compute_address.neo4j_internal[0].address : null

    # Default network mode
    network = local.use_custom_vpc ? null : "default"

    # External IP: only if assign_external_ip=true
    dynamic "access_config" {
      for_each = var.assign_external_ip ? [1] : []
      content {
        network_tier = "STANDARD"
      }
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    password  = var.password
  })

  # Instance tags for firewall targeting
  tags = ["neo4j"]

  labels = var.labels

  lifecycle {
    create_before_destroy = true
  }
}

##########################################
####### Firewall Rules
##########################################

# Internal firewall: allow VPC subnet traffic in to Neo4j ports
resource "google_compute_firewall" "neo4j_internal" {
  count   = local.use_custom_vpc ? 1 : 0
  name    = "${var.goog_cm_deployment_name}-internal"
  network = var.network_id

  # Allow traffic from the entire VPC subnet (postgres VM, Cloud Run, etc.)
  source_ranges = var.subnet_cidr != "" ? [var.subnet_cidr] : ["10.0.0.0/8"]

  allow {
    protocol = "tcp"
    ports    = ["7474", "7687"]
  }

  target_tags = ["neo4j"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# External firewall: only created when not on custom VPC, or when external IP explicitly enabled
resource "google_compute_firewall" "neo4j_external" {
  count   = !local.use_custom_vpc || var.assign_external_ip ? 1 : 0
  name    = "${var.goog_cm_deployment_name}-firewall"
  network = local.use_custom_vpc ? var.network_id : "default"

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["7474", "7687"]
  }

  target_tags = ["neo4j"]
}
