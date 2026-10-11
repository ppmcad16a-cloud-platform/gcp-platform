terraform {
  required_version = ">= 1.10"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region

  # Bill API calls (e.g. the Budgets API) to this project.
  billing_project       = var.project_id
  user_project_override = true
}
