resource "google_project_service" "apis" {
  for_each = toset([
    "compute.googleapis.com",          # networks, VMs, IPs
    "container.googleapis.com",        # GKE
    "artifactregistry.googleapis.com", # container images
    "secretmanager.googleapis.com",    # the "vault"
  ])
  service            = each.value
  disable_on_destroy = false
}

# Private registry for our service images. Kept between sessions so CI
# doesn't have to rebuild everything every time.
resource "google_artifact_registry_repository" "mern" {
  location      = var.region
  repository_id = "mern"
  format        = "DOCKER"
  description   = "Container images of the MERN microservices"

  # A tag (e.g. main-a1b2c3d) can never be overwritten - same rule as ECR.
  docker_config {
    immutable_tags = true
  }

  # Housekeeping: keep only the 10 newest versions of each image.
  cleanup_policy_dry_run = false
  cleanup_policies {
    id     = "keep-newest-10"
    action = "KEEP"
    most_recent_versions {
      keep_count = 10
    }
  }
  cleanup_policies {
    id     = "delete-older"
    action = "DELETE"
    condition {
      older_than = "2592000s" # 30 days
    }
  }

  depends_on = [google_project_service.apis]
}

# Database backups land here. Private, versioned, auto-deleted
# after 30 days.
resource "google_storage_bucket" "backups" {
  name                        = "${var.project_id}-mongo-backups"
  location                    = var.region
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 30
    }
    action {
      type = "Delete"
    }
  }
}
