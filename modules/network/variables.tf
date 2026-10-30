variable "name" {
  description = "Prefix for all network resource names"
  type        = string
}

variable "region" {
  type = string
}

variable "subnet_cidr" {
  description = "IP range for the Kubernetes nodes"
  type        = string
}

variable "pods_cidr" {
  description = "IP range for pods (secondary range)"
  type        = string
}

variable "egress_ip_self_link" {
  description = "self_link of the fixed public IP that Cloud NAT uses for all outgoing traffic"
  type        = string
}

variable "services_cidr" {
  description = "IP range for Kubernetes services (secondary range)"
  type        = string
}
