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

variable "registry_repository" {
  type    = string
  default = "mern"
}

variable "admin_cidr" {
  description = "YOUR public IP as x.x.x.x/32 - set it in terraform.tfvars"
  type        = string
}
