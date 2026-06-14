provider "google" {
  project = var.project_id
}

locals {
  # Derived flag for backwards compatibility: if enable_vpc not explicitly set,
  # fall back to the old subnet_id + network_id check.
  use_custom_vpc = var.enable_vpc || (var.subnet_id != "" && var.network_id != "")
}

##########################################
####### Static Internal IP (VPC mode)
##########################################

resource "google_compute_address" "neo4j_internal" {
  count        = var.enable_vpc ? 1 : 0
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
      type  = "hyperdisk-balanced"
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

    # The boot_disk's `type` (currently `hyperdisk-balanced`) was
    # added to this module in commit 4850457 (fix(ce): configure
    # bolt connector). VMs provisioned by an earlier version of
    # this module may have a different boot_disk.type (e.g.
    # `pd-standard`), and changing the type `forces replacement`
    # of the VM — which destroys data. For brown-field imports
    # where the existing VM is preserved, the operator needs the
    # plan to converge to "no changes" without manually migrating
    # the disk type. `ignore_changes = [boot_disk]` lets the
    # module's stated intent (`hyperdisk-balanced`) stand for new
    # VMs while accepting the existing disk's attributes for
    # imported VMs.
    #
    # Tracking:
    #   - DarojaAI/rag_research_tool#799 (consumer wiring)
    #   - DarojaAI/infra-actions#92 (import-id fix, v1.17.1)
    #   - DarojaAI/infra-actions#96 (pre-flight gate, v1.19.0)
    #   - DarojaAI/infra-actions#98 (pre-flight pin fix, v1.19.2)
    #   - DarojaAI/infra-actions#99 (composite pin bump, v1.19.3)
    #   - DarojaAI/rag_research_tool#806 (wiki pre-flight gate)
    #   - DarojaAI/rag_research_tool#807 (consumer pin bump v1.19.3)
    ignore_changes = [boot_disk]
  }
}

##########################################
####### Firewall Rules
##########################################

# Internal firewall for custom VPC (restrictive - source tags)
resource "google_compute_firewall" "neo4j_internal" {
  count   = var.enable_vpc ? 1 : 0
  name    = "${var.goog_cm_deployment_name}-internal"
  network = var.network_id

  source_tags = ["neo4j"]

  allow {
    protocol = "tcp"
    ports    = ["7474", "7687"]
  }

  target_tags = ["neo4j"]

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

# External firewall for default network or when external IP is enabled
resource "google_compute_firewall" "neo4j" {
  count   = !var.enable_vpc || var.assign_external_ip ? 1 : 0
  name    = "${var.goog_cm_deployment_name}"
  network = local.use_custom_vpc ? var.network_id : "default"

  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["7474", "7687"]
  }

  target_tags = ["neo4j"]
}
