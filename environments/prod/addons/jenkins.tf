resource "random_password" "jenkins_admin" {
  length  = 24
  special = false
}

resource "helm_release" "jenkins" {
  name             = "jenkins"
  repository       = "https://charts.jenkins.io"
  chart            = "jenkins"
  version          = "5.9.68"
  namespace        = "jenkins"
  create_namespace = true
  wait             = true
  timeout          = 900

  values = [file("${path.module}/values/jenkins.yaml")]

  set_sensitive = [
    {
      name  = "controller.admin.password"
      value = random_password.jenkins_admin.result
    },
  ]

  # The deployer Role/RoleBinding in "mern" must exist first.
  depends_on = [helm_release.platform_config]
}
