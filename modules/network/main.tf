# Our own private network (VPC). auto_create_subnetworks = false means
# "don't create a subnet in every region of the world - only what we ask for".
resource "google_compute_network" "this" {
  name                    = var.name
  auto_create_subnetworks = false
  routing_mode            = "REGIONAL"
}

# One subnet for the nodes, plus two extra ("secondary") ranges that GKE
# uses for pod IPs and service IPs. This is called a VPC-native cluster.
resource "google_compute_subnetwork" "nodes" {
  name                     = "${var.name}-nodes"
  region                   = var.region
  network                  = google_compute_network.this.id
  ip_cidr_range            = var.subnet_cidr
  private_ip_google_access = true # private nodes can still reach Google APIs (e.g. pull images)

  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = var.pods_cidr
  }

  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = var.services_cidr
  }
}

# A FIXED public IP for all traffic LEAVING the cluster.
# MongoDB Atlas will only accept connections from this IP (Phase 5).
resource "google_compute_address" "egress" {
  name   = "${var.name}-egress"
  region = var.region
}

# Cloud NAT: lets the private nodes reach the internet (Atlas, Docker Hub ...)
# without having public IPs themselves, always using the fixed IP above.
resource "google_compute_router" "this" {
  name    = "${var.name}-router"
  region  = var.region
  network = google_compute_network.this.id
}

resource "google_compute_router_nat" "this" {
  name                               = "${var.name}-nat"
  router                             = google_compute_router.this.name
  region                             = var.region
  nat_ip_allocate_option             = "MANUAL_ONLY"
  nat_ips                            = [google_compute_address.egress.self_link]
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS"

  subnetwork {
    name                    = google_compute_subnetwork.nodes.id
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }

  log_config {
    enable = true
    filter = "ERRORS_ONLY"
  }
}
