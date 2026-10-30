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

# Cloud NAT: lets the private nodes reach the internet (Atlas, Docker Hub ...)
# without having public IPs themselves, always using ONE fixed public IP
# (var.egress_ip_self_link - created in the foundation stack). MongoDB Atlas
# and the AKS/EKS API allow-lists accept that IP.
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
  nat_ips                            = [var.egress_ip_self_link]
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
