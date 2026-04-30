resource "google_container_cluster" "swiggy" {
  name     = var.cluster_name
  location = var.zone

  network    = google_compute_network.vpc.name
  subnetwork = google_compute_subnetwork.subnet.name

  # Remove default node pool; manage it separately for flexibility
  remove_default_node_pool = true
  initial_node_count       = 1

  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  release_channel {
    channel = "REGULAR"
  }

  addons_config {
    http_load_balancing {
      disabled = false
    }
  }

  deletion_protection = false
}

resource "google_container_node_pool" "swiggy_nodes" {
  name     = "${var.cluster_name}-node-pool"
  cluster  = google_container_cluster.swiggy.id
  location = var.zone

  node_count = var.node_count

  autoscaling {
    min_node_count = 1
    max_node_count = 4
  }

  node_config {
    machine_type = var.node_machine_type
    disk_size_gb = 30
    disk_type    = "pd-standard"
    image_type   = "COS_CONTAINERD"

    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
    ]

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot = true
    }
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }
}
