output "registry_url" {
  description = "Where images are pushed: <url>/<service>:<tag>"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.mern.repository_id}"
}

output "registry_repository" {
  value = google_artifact_registry_repository.mern.repository_id
}

output "backup_bucket" {
  value = google_storage_bucket.backups.name
}
