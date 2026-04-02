provider "google" {
  project = var.project_id
  region =  var.region
}

resource "google_service_account" "neo4j" {
  account_id   = "${var.goog_cm_deployment_name}"
  display_name = "${var.goog_cm_deployment_name}"
}

resource "google_project_iam_member" "neo4j_compute_viewer" {
  project = var.project_id
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.neo4j.email}"
}

##########################################
####### Compute
##########################################

resource "google_compute_instance_template" "neo4j" {
  name         = "${var.goog_cm_deployment_name}-instance-template"
  machine_type = var.machine_type

  disk {
    source_image = var.source_image
    disk_size_gb = var.disk_size
    disk_type    = "hyperdisk-balanced"
    boot         = true
  }

  network_interface {
    network = "default"
    access_config {
      network_tier = "PREMIUM"
    }
  }

  metadata_startup_script = templatefile("${path.module}/startup.sh", {
    password                = var.password
    nodeCount               = var.node_count
    goog_cm_deployment_name = var.goog_cm_deployment_name
  })

   service_account {
    email  = google_service_account.neo4j.email
    scopes = ["cloud-platform"]
  }
}

resource "google_compute_region_instance_group_manager" "neo4j" {
  name                      = "${var.goog_cm_deployment_name}-instance-group-manager"
  distribution_policy_zones = var.zones
  target_size               = var.node_count
  base_instance_name        = var.goog_cm_deployment_name

  version {
    instance_template = google_compute_instance_template.neo4j.id
  }

  named_port {
    name = "neo4j-http"
    port = 7474
  }

  named_port {
    name = "neo4j-bolt"
    port = 7687
  }
}

##########################################
####### Network
##########################################

resource "google_compute_firewall" "neo4j" {
  name    = "${var.goog_cm_deployment_name}"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["7474", "7687"]
  }

  source_ranges = ["0.0.0.0/0"]
}
