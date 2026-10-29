# ---------------------------------------------------------------
# GitHub Actions pushes service images here - keyless.
# Only the MAIN branch of each service repo may act as this robot,
# and the robot may only ADD images to the "mern" registry
# (writer = push/tag, no delete, no other registries).
# ---------------------------------------------------------------
locals {
  github_org = "ppmcad16a-cloud-platform"

  # GitHub writes PERMANENT ids into the identity card ("immutable subject"):
  #   repo:<org>@<org id>/<repo>@<repo id>:ref:refs/heads/main
  # A repo that is deleted and re-created under the same name gets a NEW id,
  # so it can never inherit these permissions.
  # Look up an id with:  gh api repos/<org>/<repo> --jq .id
  github_org_id = "308835253"
  github_repo_ids = {
    "api-gateway-service"  = "1363132826"
    "identity-service"     = "1347625227"
    "catalog-service"      = "1345164391"
    "commerce-service"     = "1363104512"
    "notification-service" = "1311276453"
    "client-service"       = "1363120914"
    "seed-db-service"      = "1363165699"
  }

  services = [
    "api-gateway-service",
    "identity-service",
    "catalog-service",
    "commerce-service",
    "notification-service",
    "client-service",
    "seed-db-service",
  ]
  # The GitHub login pool created in bootstrap/.
  github_pool = "projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/github"
}

data "google_project" "this" {}

resource "google_service_account" "ci_push" {
  account_id   = "gha-push"
  display_name = "GitHub Actions - push service images (main branch only)"
}

resource "google_artifact_registry_repository_iam_member" "ci_push" {
  location   = google_artifact_registry_repository.mern.location
  repository = google_artifact_registry_repository.mern.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.ci_push.email}"
}

# "A run on the main branch of <service> may act as gha-push" - one rule per service.
resource "google_service_account_iam_member" "ci_push_wif" {
  for_each           = toset(local.services)
  service_account_id = google_service_account.ci_push.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "principal://iam.googleapis.com/${local.github_pool}/subject/repo:${local.github_org}@${local.github_org_id}/${each.value}@${local.github_repo_ids[each.value]}:ref:refs/heads/main"
}

output "ci_push_service_account" {
  value = google_service_account.ci_push.email
}

output "ci_push_wif_provider" {
  value = "${local.github_pool}/providers/github-oidc"
}
