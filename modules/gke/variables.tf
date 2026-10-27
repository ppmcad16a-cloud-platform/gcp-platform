variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "location" {
  description = "A ZONE (e.g. asia-south1-a) = zonal cluster (one free per billing account)"
  type        = string
}

variable "network_id" {
  type = string
}

variable "subnet_id" {
  type = string
}

variable "pods_range_name" {
  type = string
}

variable "services_range_name" {
  type = string
}

variable "authorized_cidrs" {
  description = "Who may talk to the Kubernetes API (kubectl). Keep this small!"
  type = list(object({
    cidr = string
    name = string
  }))
}

variable "machine_type" {
  type    = string
  default = "e2-standard-2" # 2 vCPU, 8 GB RAM
}

variable "min_nodes" {
  type    = number
  default = 2
}

variable "max_nodes" {
  type    = number
  default = 3
}

variable "disk_size_gb" {
  type    = number
  default = 50
}

variable "spot" {
  description = "Spot VMs are ~60-90% cheaper but Google may reclaim them at any time"
  type        = bool
  default     = false
}
