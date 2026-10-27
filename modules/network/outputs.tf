output "network_id" {
  value = google_compute_network.this.id
}

output "subnet_id" {
  value = google_compute_subnetwork.nodes.id
}

output "pods_range_name" {
  value = "pods"
}

output "services_range_name" {
  value = "services"
}

output "egress_ip" {
  description = "Fixed public IP used by everything leaving the cluster"
  value       = google_compute_address.egress.address
}
