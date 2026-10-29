# ---------------------------------------------------------------
# who may touch the database backups (GCS copy) - keyless,
# through Workload Identity: a Kubernetes service account in GKE's
# "jenkins" namespace acts as one Google service account.
#   jenkins/mongo-backup  -> mongo-backup@  : ADD objects only (no read, no
#                                             delete) + read the backup-ro DB URI
#   jenkins/mongo-restore -> mongo-restore@ : READ objects only + read the
#                                             age key + the restore-drill DB URI
# ---------------------------------------------------------------
locals {
  dr_identities = {
    "mongo-backup" = {
      display     = "MERN backup job - add backups only"
      bucket_role = "roles/storage.objectCreator"
      secrets     = ["mern-mongo-backup-uri"]
    }
    "mongo-restore" = {
      display     = "MERN restore drill - read backups only"
      bucket_role = "roles/storage.objectViewer"
      secrets     = ["mern-backup-age-key", "mern-mongo-restore-drill-uri"]
    }
  }

  # one entry per (identity, secret) pair, e.g. "mongo-restore/mern-backup-age-key"
  dr_secret_grants = merge([
    for sa, cfg in local.dr_identities : { for s in cfg.secrets : "${sa}/${s}" => { sa = sa, secret = s } }
  ]...)
}

resource "google_service_account" "dr" {
  for_each     = local.dr_identities
  account_id   = each.key
  display_name = each.value.display
}

resource "google_storage_bucket_iam_member" "dr" {
  for_each = local.dr_identities
  bucket   = google_storage_bucket.backups.name
  role     = each.value.bucket_role
  member   = "serviceAccount:${google_service_account.dr[each.key].email}"
}

resource "google_secret_manager_secret_iam_member" "dr" {
  for_each  = local.dr_secret_grants
  secret_id = each.value.secret
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.dr[each.value.sa].email}"
}

resource "google_service_account_iam_member" "dr_workload_identity" {
  for_each           = local.dr_identities
  service_account_id = google_service_account.dr[each.key].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[jenkins/${each.key}]"
}

output "dr_service_accounts" {
  value = { for k, sa in google_service_account.dr : k => sa.email }
}
