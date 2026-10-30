# GKE's FIXED outgoing IP (Cloud NAT uses it for everything leaving the
# cluster). It lives here - in the permanent stack - instead of in the
# cluster stack, so it already exists before any cluster is created:
#   - AKS and EKS put it on their API allow-lists (Jenkins in GKE deploys to
#     them) and no longer have to wait for GKE -> all 3 clusters start at once
#   - the IP never changes between sessions
# Cost: about $7/month while no cluster uses it (GCP charges idle static IPs).
resource "google_compute_address" "egress" {
  name   = "prod-egress"
  region = var.region

  depends_on = [google_project_service.apis]
}
