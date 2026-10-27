module "network" {
  source = "../../../modules/network"

  name          = "prod"
  region        = var.region
  subnet_cidr   = "10.30.0.0/20"   # nodes
  services_cidr = "10.30.16.0/20"  # Kubernetes services
  pods_cidr     = "10.30.128.0/17" # pods
}

module "gke" {
  source = "../../../modules/gke"

  project_id          = var.project_id
  name                = "prod-gke"
  location            = var.zone
  network_id          = module.network.network_id
  subnet_id           = module.network.subnet_id
  pods_range_name     = module.network.pods_range_name
  services_range_name = module.network.services_range_name

  authorized_cidrs = [
    { cidr = var.admin_cidr, name = "admin" },
  ]
}

# The nodes may PULL (only pull) images from our registry.
resource "google_artifact_registry_repository_iam_member" "nodes_pull" {
  project    = var.project_id
  location   = var.region
  repository = var.registry_repository
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${module.gke.node_service_account_email}"
}
