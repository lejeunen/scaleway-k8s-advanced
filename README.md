# Scaleway K8s Advanced

[![GitHub](https://img.shields.io/badge/GitHub-lejeunen%2Fscaleway--k8s--advanced-blue?logo=github)](https://github.com/lejeunen/scaleway-k8s-advanced)

Building on the foundations of [scaleway-starter-kit](https://github.com/lejeunen/scaleway-starter-kit), this project takes a **Kubernetes-first** approach to sovereign cloud infrastructure on Scaleway.

## Why Sovereign Cloud?

European regulations (GDPR, upcoming EUCS certification) increasingly require that data stays within EU borders, processed by EU-headquartered providers. Scaleway, as a French cloud provider with datacenters in Paris and Amsterdam, offers a credible alternative to US hyperscalers for organizations that need **data sovereignty** without sacrificing modern cloud-native tooling.

This project demonstrates that a production-grade Kubernetes platform can be built entirely on sovereign infrastructure — portable enough to move between providers, yet fully leveraging Scaleway's managed services.

## The Approach

Bootstrap a Kapsule cluster with Terraform/Terragrunt, then manage everything else — cloud resources included — through GitOps (FluxCD) and Crossplane. This design maximizes multi-cloud portability by expressing infrastructure as Kubernetes resources rather than provider-specific IaC.

```
┌───────────────────────────────────────────────────────────┐
│                     GitOps (FluxCD)                       │
│          Declarative, git-driven reconciliation           │
│                                                           │
│  ┌────────────────┐  ┌───────────────┐  ┌──────────────┐  │
│  │    Platform    │  │ Observability │  │ Applications │  │
│  │   Components   │  │     Stack     │  │              │  │
│  │                │  │               │  │ Matrix/      │  │
│  │ Envoy Gateway  │  │ Prometheus    │  │  Element     │  │
│  │  (Gateway API) │  │ Grafana       │  │ Matomo       │  │
│  │ cert-manager   │  │ Loki          │  │ Sovereign    │  │
│  │ External       │  │ Tempo         │  │  Cloud       │  │
│  │   Secrets      │  │ Alloy         │  │  Wisdom      │  │
│  │ CloudNativePG  │  │               │  │ Jeanne       │  │
│  │ Crossplane     │  │               │  │  (AI agent)  │  │
│  └────────────────┘  └───────────────┘  └──────────────┘  │
├───────────────────────────────────────────────────────────┤
│                   Crossplane (Scaleway)                    │
│           Cloud resources as Kubernetes CRs               │
│        S3 Bucket · Container Registry · DNS · ...         │
├───────────────────────────────────────────────────────────┤
│               Kapsule (Managed Kubernetes)                │
│                   VPC + Private Network                   │
├───────────────────────────────────────────────────────────┤
│            Terragrunt / Terraform (bootstrap)             │
└───────────────────────────────────────────────────────────┘
```

This project favors learning-by-doing: each commit is self-contained and tells a story. Browse the [commit history](https://github.com/lejeunen/scaleway-k8s-advanced/commits/main) for step-by-step implementation details.

## Repository Structure

Each top-level directory is owned by a specific tool — you always know what manages a resource by where it lives:

| Directory | Managed by | Purpose |
|-----------|------------|---------|
| `infrastructure/` | Terraform/Terragrunt | Bootstrap: VPC, Kapsule cluster, Secret Manager |
| `gitops/system/base/` | Flux | Per-component manifests (HelmRelease, namespace, CRD instances) |
| `gitops/system/dev/` | Flux | Per-component Flux Kustomizations with `dependsOn` DAG |
| `gitops/apps/` | Flux | Application workloads |
| `gitops/clusters/dev/` | Flux | Entry points (`system.yaml`, `apps.yaml`) and FluxInstance |

Flux reconciliation: per-component DAG (see `REFACTORING.md` for the full dependency graph)

## Key Design Decisions

- **Crossplane over pure Terraform** — Once the cluster exists, managing cloud resources as K8s custom resources keeps everything in a single control plane and reconciliation loop. No more split between "infra deploy" and "app deploy".
- **FluxCD over ArgoCD** — Flux follows a decentralized, pull-based model that fits well with a mono-repo layout. It's lighter-weight and doesn't require a UI or additional RBAC setup.
- **Terragrunt for bootstrap only** — Terraform/Terragrunt is the right tool for the initial chicken-and-egg problem (creating the cluster, seeding Secret Manager with credentials). After that, Crossplane takes over.
- **Gateway API over Ingress** — The Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/) is the successor to the Ingress resource, offering weighted traffic splitting (canary deployments), header-based routing, and cross-namespace references. Since `ingress-nginx` reaches [end-of-life in March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), we use Gateway API from the start.
- **Envoy Gateway as Gateway API implementation** — Kapsule's managed Cilium supports Gateway API upstream, but Scaleway does not expose the `gatewayAPI.enabled` flag on managed clusters (as of Feb 2026). Since the Cilium installation in `kube-system` is managed by Scaleway and may be overwritten during auto-upgrades, we deploy [Envoy Gateway](https://gateway.envoyproxy.io/) (the CNCF reference implementation) as a standalone controller. All routing manifests use the portable Gateway API spec — if Scaleway enables Cilium Gateway API in the future, the implementation can be swapped with zero changes to route definitions.
- **External Secrets over sealed-secrets** — ESO integrates with Scaleway's Secret Manager, keeping secrets out of git entirely rather than encrypting them in-repo. Terragrunt creates secret shells (name/description/tags); a dedicated script (`scripts/push-secrets.sh`) pushes sensitive values via the `scw` CLI, keeping them out of Terraform state. ESO syncs them into the cluster.
- **Grafana Alloy over Promtail** — Alloy is Grafana's unified telemetry collector (successor to Promtail and Grafana Agent). A single DaemonSet collects logs today and will also collect traces when Tempo is added, eliminating the need for a separate OpenTelemetry Collector. Pragmatic choice: best integration with the Grafana stack (Loki, Tempo, Prometheus) while remaining open-source.
- **Crossplane provider auto-install** — The Scaleway provider is installed via the Crossplane Helm chart's `provider.packages` value rather than a separate Provider CR. This avoids the kustomize dry-run problem (Provider CR is a CRD instance that needs the Crossplane CRDs to exist first) and keeps the three-phase pattern clean.
- **Per-component DAG over monolithic phases** — Each system component (cert-manager, ESO, Envoy Gateway, Crossplane, etc.) gets its own Flux Kustomization with explicit `dependsOn` edges. This replaced an earlier 4-phase pattern that failed on fresh cluster bootstrap because kustomize dry-run rejects CRD instances when CRDs don't exist yet. The DAG gives independent failure isolation, per-component retries, and reliable from-scratch bootstrapping.

## Bootstrap from Scratch

```bash
# 1. Infrastructure (secret-manager creates shells only, no sensitive data in state)
cd infrastructure/dev/vpc && terragrunt apply
cd ../kapsule && terragrunt apply
cd ../secret-manager && terragrunt apply

# 2. Push secret values via scw CLI (bypasses Terraform state)
source .env && ./scripts/push-secrets.sh

# 3. Kubeconfig (KUBECONFIG is set via .env)
cd infrastructure/dev/kapsule
terragrunt output -json kubeconfig | jq -r '.[0].config_file' > ../.kubeconfig

# 4. Bootstrap secret for External Secrets Operator
kubectl create namespace external-secrets
kubectl create secret generic scaleway-credentials -n external-secrets \
  --from-literal=access-key=$SCW_ACCESS_KEY \
  --from-literal=secret-key=$SCW_SECRET_KEY

# 5. SSH deploy key for Flux
ssh-keygen -t ed25519 -f flux-deploy-key -N "" -C "flux-dev"
# Add the public key (flux-deploy-key.pub) to GitHub repo Settings > Deploy keys (read-only)
kubectl create namespace flux-system
kubectl create secret generic flux-system -n flux-system \
  --from-file=identity=flux-deploy-key \
  --from-file=identity.pub=flux-deploy-key.pub \
  --from-literal=known_hosts="$(ssh-keyscan github.com 2>/dev/null)"

# 6. Install Flux Operator
helm install flux-operator oci://ghcr.io/controlplaneio-fluxcd/charts/flux-operator \
  -n flux-system

# 7. Apply FluxInstance (triggers full DAG reconciliation)
kubectl apply -f gitops/clusters/dev/flux-instance.yaml
```

After step 7, Flux picks up `system.yaml` and `apps.yaml` from `gitops/clusters/dev/` and reconciles all components following the dependency graph.

## Prerequisites

- [Scaleway account](https://console.scaleway.com/) with API keys configured
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.50
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli)

## Roadmap

### Phase 1 — Foundation ✅
Terragrunt-managed infrastructure to get a production-ready Kapsule cluster:
- [x] VPC with private network
- [x] Kapsule cluster with autoscaling node pool
- [x] Automatic K8s version upgrades (Sunday 3am maintenance window)
- [x] PodSecurity enforcement via namespace labels (Kapsule enables the [PodSecurity admission controller](https://kubernetes.io/docs/concepts/security/pod-security-admission/) by default)
- [x] Environment-aware safety: `delete_additional_resources` protects production from accidental resource deletion
- [x] Secret Manager bootstrapping (Terragrunt creates shells, `scripts/push-secrets.sh` pushes values via scw CLI)

### Phase 2 — GitOps ✅
FluxCD bootstrap to manage all subsequent components declaratively:
- [x] Gateway API with Envoy Gateway (traffic routing, canary deployments)
- [x] TLS automation (cert-manager with Let's Encrypt DNS-01 wildcard)
- [x] Secret management (External Secrets Operator + Scaleway Secret Manager)
- [x] CloudNativePG operator (in-cluster PostgreSQL, CNCF)
- [x] external-dns (automatic DNS records from Gateway API HTTPRoutes → Scaleway DNS)
- [x] Observability stack
  - [x] Prometheus (metrics collection + alerting rules)
  - [x] Grafana (dashboards)
  - [x] Loki (log aggregation) + Grafana Alloy (collector DaemonSet, replaces Promtail)
  - [x] Tempo (distributed tracing — Alloy already in place as trace collector)

### Phase 3 — Crossplane ✅
Cloud resources as Kubernetes custom resources — Crossplane v2.2 with the Scaleway provider (Upjet-generated, 255 managed resources). Credentials synced from Secret Manager via ESO, same pattern as DNS credentials:
- [x] Crossplane with Scaleway provider (auto-installed via `provider.packages`)
- [x] Container Registry (sovereign image storage, private)
- [x] S3 bucket (CloudNativePG backups, globally unique name)

### Phase 4 — Application ✅
Deploy [sovereign-cloud-wisdom](https://github.com/lejeunen/sovereign-cloud-wisdom) as a real workload. The Helm chart in the app repo is **platform-agnostic** (Deployment + Service only) — all Scaleway-specific wiring (CNPG, ESO, Gateway routing) lives in this repo:
- [x] Platform-agnostic Helm chart (DB config via ConfigMap, credentials via Secret — no CNPG/ESO/Scaleway coupling)
- [x] CloudNativePG Cluster instance (1-instance PostgreSQL, auto-created credentials)
- [x] ExternalSecret for private registry pull credentials (ESO → Scaleway Secret Manager)
- [x] HTTPRoute on `wisdom.scw.sovereigncloudwisdom.eu` via Envoy Gateway
- [x] CNPG S3 backups (barman-cloud plugin, daily scheduled, 3d retention)
- [x] DNS record for `wisdom.scw.sovereigncloudwisdom.eu` (via external-dns)
- [x] Grafana HTTPRoute on `grafana.scw.sovereigncloudwisdom.eu`
- [x] Flux image automation (ImageRepository + ImagePolicy + ImageUpdateAutomation, timestamp-SHA tags)
- [x] API auth token via ExternalSecret

### Phase 5 — Sovereign Applications ✅
Real workloads running entirely on sovereign infrastructure:
- [x] Matomo analytics (raw manifests, MariaDB, GeoIP, OIDC-protected)
- [x] Matrix homeserver (Element Server Suite: Synapse + MAS + Element Web + Element Admin)
  - [x] 2 independent CNPG clusters (synapse + MAS), daily S3 backups
  - [x] Google OIDC for Element Web and Element Admin
  - [x] Federation enabled (port 443/8448)
  - [x] `.well-known` delegation from starter-kit cluster
- [x] Jeanne — autonomous DevOps agent (OpenClaw operator + Devstral on Matrix)
  - [x] GitHub App integration for PR workflow
  - [x] Read-only cluster RBAC (CiliumNetworkPolicy, Flux, CNPG, Crossplane, etc.)
  - [x] Daily VolumeSnapshot backup of persistent memory (scw-snapshot-retain)

### Phase 6 — Security Hardening 📋
Defense in depth — perimeter, internal, access control and audit:
- [x] Cilium NetworkPolicies (GitOps — per-namespace, all namespaces except flux-system)
- [x] Pod Security Standards (GitOps — `enforce: baseline` + `warn: restricted` labels on all namespaces)
- [ ] Kapsule API server allowed IPs (Crossplane `Acl` — restrict who can `kubectl` to the cluster)
- [ ] Security groups on Kapsule node pool (Terraform — restrict inbound/outbound at instance level)
- [ ] Edge Services WAF pipeline (Crossplane — OWASP CRS protection on public HTTP endpoints)
- [ ] PodDisruptionBudgets (GitOps — protect workloads during Kapsule auto-upgrade node drains)
- [ ] Envoy Gateway rate limiting (GitOps — `BackendTrafficPolicy` to throttle abusive clients at L7)
- [ ] IAM least-privilege (Crossplane `Application` + `Policy` — scoped API keys per service instead of broad credentials)
- [ ] Audit Trail (Scaleway console — cloud-level logging of all API actions for compliance)
- [ ] RBAC hardening (namespace-scoped roles — relevant for multi-team production, optional for single-operator)

### Phase 7 — CI/CD 📋
- [ ] GitHub Actions pipeline (build, test, push image on commit)
- [ ] OIDC federation with Scaleway (no stored credentials)
