variable "project_id" {
  type    = string
  default = "project-899ced78-a554-40c2-96c"
}

variable "region" {
  type    = string
  default = "asia-south1"
}

variable "billing_account_id" {
  type    = string
  default = "01DA0B-15E72F-FF101F"
}

variable "github_org" {
  type    = string
  default = "ppmcad16a-cloud-platform"
}

variable "github_repo" {
  type    = string
  default = "gcp-platform"
}

variable "budget_amount" {
  description = "Monthly budget in the billing account currency (INR) - about USD 10"
  type        = number
  default     = 850
}

variable "budget_currency" {
  type    = string
  default = "INR"
}

variable "alert_email" {
  type    = string
  default = "rishav1994sonai@gmail.com"
}
