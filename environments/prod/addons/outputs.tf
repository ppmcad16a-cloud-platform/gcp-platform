output "ingress_ip" {
  value = data.google_compute_address.ingress.address
}

output "grafana_admin_password" {
  description = "Show with: terraform output -raw grafana_admin_password"
  value       = random_password.grafana_admin.result
  sensitive   = true
}
