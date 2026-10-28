# The fixed IP created by the cluster stack.
data "google_compute_address" "ingress" {
  name   = "prod-ingress"
  region = var.region
}

# Cloudflare publishes the IP ranges its servers use. Only these (plus you)
# may reach the front door - visitors can't bypass Cloudflare.
data "http" "cloudflare_ipv4" {
  url = "https://www.cloudflare.com/ips-v4"
}

locals {
  cloudflare_cidrs = [
    for line in split("\n", trimspace(data.http.cloudflare_ipv4.response_body)) :
    trimspace(line) if trimspace(line) != ""
  ]
}

# 1. Envoy Gateway: the controller that runs our front door.
resource "helm_release" "envoy_gateway" {
  name             = "envoy-gateway"
  repository       = "oci://docker.io/envoyproxy"
  chart            = "gateway-helm"
  version          = var.envoy_gateway_version
  namespace        = "envoy-gateway-system"
  create_namespace = true
  wait             = true
  timeout          = 600
}

# 2. External Secrets Operator: copies vault secrets into Kubernetes.
resource "helm_release" "external_secrets" {
  name             = "external-secrets"
  repository       = "https://charts.external-secrets.io"
  chart            = "external-secrets"
  version          = var.external_secrets_version
  namespace        = "external-secrets"
  create_namespace = true
  wait             = true
  timeout          = 600

  values = [yamlencode({
    serviceAccount = {
      # Link to the Google service account (Workload Identity).
      annotations = {
        "iam.gke.io/gcp-service-account" = google_service_account.eso.email
      }
    }
  })]

  depends_on = [google_service_account_iam_member.eso_workload_identity]
}

# 3. Our own cluster-wide objects (gateway, secret store, namespaces),
#    packaged as a small local Helm chart. Installed AFTER the two above,
#    because it uses the object types (CRDs) they install.
resource "helm_release" "platform_config" {
  name      = "platform-config"
  chart     = "${path.module}/charts/platform-config"
  namespace = "envoy-gateway-system"
  wait      = true

  values = [yamlencode({
    cloud        = "gcp"
    ingressIP    = data.google_compute_address.ingress.address
    sourceRanges = concat(local.cloudflare_cidrs, [var.admin_cidr])
    secretStore = {
      gcpsm = {
        projectID = var.project_id
      }
    }
    # Who may deploy into "mern": the Jenkins build pods' service account.
    deployerSubjects = [
      {
        kind      = "ServiceAccount"
        name      = "jenkins-deployer"
        namespace = "jenkins"
      },
    ]
  })]

  depends_on = [
    helm_release.envoy_gateway,
    helm_release.external_secrets,
    google_secret_manager_secret_iam_member.eso_read,
  ]
}
