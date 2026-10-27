output "cluster_name" {
  value = google_container_cluster.this.name
}

output "location" {
  value = google_container_cluster.this.location
}

output "node_service_account_email" {
  value = google_service_account.nodes.email
}
