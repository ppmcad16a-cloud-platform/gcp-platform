output "cluster_name" {
  value = module.gke.cluster_name
}

output "egress_ip" {
  description = "Fixed outgoing IP of the cluster - global-platform adds it to the MongoDB Atlas IP access list"
  value       = data.google_compute_address.egress.address
}

output "get_credentials" {
  description = "Run this to point kubectl at the cluster"
  value       = "gcloud container clusters get-credentials ${module.gke.cluster_name} --zone ${module.gke.location} --project ${var.project_id}"
}

output "ingress_ip" {
  description = "Public IP of the web entrance - Cloudflare's origin for GCP"
  value       = google_compute_address.ingress.address
}
