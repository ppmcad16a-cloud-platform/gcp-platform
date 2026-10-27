# Nodes get their OWN service account with only the permissions a node needs
# (write logs/metrics), instead of Google's default account (which has Editor
# on the whole project - far too much).
resource "google_service_account" "nodes" {
  account_id   = "${var.name}-nodes"
  display_name = "GKE nodes of ${var.name} (minimal permissions)"
}

resource "google_project_iam_member" "nodes" {
  project = var.project_id
  role    = "roles/container.defaultNodeServiceAccount"
  member  = "serviceAccount:${google_service_account.nodes.email}"
}

resource "google_container_cluster" "this" {
  name       = var.name
  location   = var.location
  network    = var.network_id
  subnetwork = var.subnet_id

  # We manage the node pool ourselves (below), so delete the default one.
  remove_default_node_pool = true
  initial_node_count       = 1

  # We destroy and recreate this cluster every session.
  deletion_protection = false

  # Google upgrades Kubernetes for us, at a tested pace.
  release_channel {
    channel = "REGULAR"
  }

  # Dataplane V2 actually ENFORCES Kubernetes NetworkPolicies (our firewall
  # rules between pods, Phase 6).
  datapath_provider = "ADVANCED_DATAPATH"

  ip_allocation_policy {
    cluster_secondary_range_name  = var.pods_range_name
    services_secondary_range_name = var.services_range_name
  }

  # Private nodes: VMs have NO public IP (not reachable from the internet).
  # The control plane keeps a public endpoint, restricted below.
  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
  }

  # Only these IPs may talk to the Kubernetes API.
  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.authorized_cidrs
      content {
        cidr_block   = cidr_blocks.value.cidr
        display_name = cidr_blocks.value.name
      }
    }
  }

  # Workload Identity: pods can act as Google service accounts
  # WITHOUT key files (used by External Secrets in Phase 6).
  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }

  # Only Kubernetes' own system logs/metrics go to Google Cloud (cheap);
  # our apps are monitored by our own Prometheus/Loki (Phase 6/9).
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS"]
  }

  monitoring_config {
    enable_components = ["SYSTEM_COMPONENTS"]
    managed_prometheus {
      enabled = false
    }
  }
}

resource "google_container_node_pool" "default" {
  name               = "default"
  cluster            = google_container_cluster.this.id
  location           = var.location
  initial_node_count = var.min_nodes

  # Cluster autoscaler: adds a node when pods don't fit, removes it when idle.
  autoscaling {
    min_node_count = var.min_nodes
    max_node_count = var.max_nodes
  }

  management {
    auto_repair  = true # a broken node is replaced automatically
    auto_upgrade = true
  }

  # During upgrades: add 1 new node first, never take one away first
  # (zero downtime).
  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }

  node_config {
    machine_type    = var.machine_type
    disk_size_gb    = var.disk_size_gb
    disk_type       = "pd-balanced"
    spot            = var.spot
    service_account = google_service_account.nodes.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]

    # Pods can't read the node's own credentials; they use Workload Identity.
    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    # Verified boot: protects against tampered boot software.
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    labels = {
      pool = "default"
    }
  }

  depends_on = [google_project_iam_member.nodes]
}
