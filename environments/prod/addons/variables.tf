variable "project_id" {
  type    = string
  default = "project-899ced78-a554-40c2-96c"
}

variable "region" {
  type    = string
  default = "asia-south1"
}

variable "zone" {
  type    = string
  default = "asia-south1-a"
}

variable "cluster_name" {
  type    = string
  default = "prod-gke"
}

variable "admin_cidr" {
  description = "YOUR public IP x.x.x.x/32 - may reach the front door directly for testing"
  type        = string
}

variable "envoy_gateway_version" {
  type    = string
  default = "v1.9.2"
}

variable "external_secrets_version" {
  type    = string
  default = "2.12.0"
}

variable "app_secret_names" {
  description = "Secret Manager secrets the cluster may read (created by global-platform)"
  type        = list(string)
  default = [
    "mern-mongo-uri",
    "mern-jwt-secret",
    "mern-seed-admin-password",
    "mern-origin-tls-crt",
    "mern-origin-tls-key",
  ]
}
