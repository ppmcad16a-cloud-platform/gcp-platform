output "ingress_ip" {
  value = data.google_compute_address.ingress.address
}
