# gcp-platform

Terraform for everything the MERN platform runs on **Google Cloud** — the **primary** cloud that serves all shoppers and also hosts Jenkins (continuous delivery) and the central Grafana.

**Region:** `asia-south1` (cluster in zone `asia-south1-a`) · **Terraform** 1.16 · **Remote state:** GCS bucket `<project>-tfstate` (versioned)

## Stacks

Each folder is its own Terraform stack with its own state. Apply them in this order.

| Stack | Creates | Lifetime |
|---|---|---|
| `bootstrap/` | state bucket, Workload Identity Federation pool for GitHub, plan/apply service accounts, monthly budget with e-mail alert | once |
| `environments/prod/foundation/` | Artifact Registry `mern` (immutable tags, keep newest 10), backup bucket, CI push identity `gha-push`, backup/restore identities, **permanent egress IP `prod-egress`** | permanent |
| `environments/prod/cluster/` | VPC + subnet with pod/service ranges, Cloud NAT using `prod-egress`, GKE Standard cluster `prod-gke` (private nodes, Workload Identity, Dataplane V2), node pool 2–3 × `e2-standard-2`, static ingress IP | per session |
| `environments/prod/addons/` | Envoy Gateway, External Secrets (+ Secret Manager access), kube-prometheus-stack, Loki, Alloy, OpenCost, **Jenkins** (Configuration-as-Code), **central Grafana** dashboards and data sources, platform-config chart (gateway, TLS, RBAC, secret store) | per session |

Reusable modules: `modules/network`, `modules/gke`.

## Dependencies

| Depends on | For |
|---|---|
| [observability-platform](https://github.com/ppmcad16a-cloud-platform/observability-platform) | alert rules + dashboards module (`?ref=v1.1.0`) |
| [global-platform](https://github.com/ppmcad16a-cloud-platform/global-platform) | writes the app secrets (DB URI, JWT, TLS, Slack) into Secret Manager that the add-ons read |
| [platform-deployments](https://github.com/ppmcad16a-cloud-platform/platform-deployments) | Jenkins jobs (deploy, backup, restore drill) load their pipelines from it |

| Used by | For |
|---|---|
| [azure-platform](https://github.com/ppmcad16a-cloud-platform/azure-platform), [aws-platform](https://github.com/ppmcad16a-cloud-platform/aws-platform) | read `gke_egress_ip` from this repo's foundation state to let Jenkins reach their Kubernetes APIs |
| [global-platform](https://github.com/ppmcad16a-cloud-platform/global-platform) | reads the cluster's ingress/egress IPs for DNS, the load balancer and the Atlas allow-list |
| [platform-automation](https://github.com/ppmcad16a-cloud-platform/platform-automation) | applies `cluster` and `addons` at session start and destroys them at the end |

## Usage

Normally the session stacks are driven by `platform-automation` (`up.yml` / `down.yml`). By hand:

```bash
gcloud auth login && gcloud auth application-default login
cd environments/prod/foundation && terraform init && terraform plan && terraform apply

echo "admin_cidr = \"$(curl -s https://api.ipify.org)/32\"" > ../cluster/terraform.tfvars   # git-ignored
cp ../cluster/terraform.tfvars ../addons/terraform.tfvars
cd ../cluster && terraform init && terraform apply
cd ../addons  && terraform init && terraform apply
terraform output -raw jenkins_admin_password      # Jenkins / Grafana admin passwords
```

`admin_cidr` (your public IP) is the only required input; everything else has defaults for this project — see the [setup guide](https://github.com/ppmcad16a-cloud-platform/core-cloud-platform/blob/main/docs/04-setup-guide.md) for using your own accounts.

## Rules

* Plain `terraform init` — never `-upgrade`; the committed `.terraform.lock.hcl` pins the provider versions.
* No secrets in this repo; `terraform.tfvars` holds only your IP and is git-ignored.
* Never `terraform destroy -refresh=false` on `addons` — with a stale cluster token it can empty the state while releases keep running.
