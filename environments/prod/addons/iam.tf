# A Google service account just for External Secrets ...
resource "google_service_account" "eso" {
  account_id   = "external-secrets"
  display_name = "External Secrets Operator (prod-gke) - read app secrets only"
}

# ... that may READ ONLY our app secrets (secret by secret, not project-wide).
resource "google_secret_manager_secret_iam_member" "eso_read" {
  for_each  = toset(var.app_secret_names)
  secret_id = each.value
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.eso.email}"
}

# Workload Identity: the Kubernetes service account "external-secrets" in
# namespace "external-secrets" may act as this Google service account.
# No key file is ever created.
resource "google_service_account_iam_member" "eso_workload_identity" {
  service_account_id = google_service_account.eso.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets]"
}
