output "cluster_name" {
  value = module.gke.cluster_name
}

output "egress_ip" {
  description = "Add this to the MongoDB Atlas IP access list (Phase 5)"
  value       = module.network.egress_ip
}

output "get_credentials" {
  description = "Run this to point kubectl at the cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone ${module.gke.location} --project ${var.project_id}"
}

output "ingress_ip" {
  description = "Public IP of the web entrance - Cloudflare's origin for GCP"
  value       = google_compute_address.ingress.address
}
