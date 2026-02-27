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
│  ┌────────────────┐  ┌───────────────┐                    │
│  │    Platform    │  │ Observability │                    │
│  │   Components   │  │     Stack     │                    │
│  │                │  │               │                    │
│  │ Envoy Gateway  │  │ Prometheus    │                    │
│  │  (Gateway API) │  │ Grafana       │                    │
│  │ cert-manager   │  │ Loki          │                    │
│  │ External       │  │ Tempo         │                    │
│  │   Secrets      │  │ Alloy         │                    │
│  │ CloudNativePG  │  │               │                    │
│  │ Crossplane     │  │               │                    │
│  └────────────────┘  └───────────────┘                    │
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
| `gitops/platform/` | Flux | Operators installed via HelmReleases |
| `gitops/platform-config/` | Flux | CRD instances that configure operators (ClusterIssuer, ProviderConfig, ...) |
| `gitops/crossplane/` | Crossplane | Cloud infrastructure resources (S3 buckets, Container Registry, ...) |
| `gitops/apps/` | Flux | Application workloads |
| `gitops/clusters/` | Flux | Per-environment Kustomization entrypoints and variable substitution |

Flux reconciliation order: **platform** → **platform-config** → **crossplane** → **apps**

## Key Design Decisions

- **Crossplane over pure Terraform** — Once the cluster exists, managing cloud resources as K8s custom resources keeps everything in a single control plane and reconciliation loop. No more split between "infra deploy" and "app deploy".
- **FluxCD over ArgoCD** — Flux follows a decentralized, pull-based model that fits well with a mono-repo layout. It's lighter-weight and doesn't require a UI or additional RBAC setup.
- **Terragrunt for bootstrap only** — Terraform/Terragrunt is the right tool for the initial chicken-and-egg problem (creating the cluster, seeding Secret Manager with credentials). After that, Crossplane takes over.
- **Gateway API over Ingress** — The Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/) is the successor to the Ingress resource, offering weighted traffic splitting (canary deployments), header-based routing, and cross-namespace references. Since `ingress-nginx` reaches [end-of-life in March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), we use Gateway API from the start.
- **Envoy Gateway as Gateway API implementation** — Kapsule's managed Cilium supports Gateway API upstream, but Scaleway does not expose the `gatewayAPI.enabled` flag on managed clusters (as of Feb 2026). Since the Cilium installation in `kube-system` is managed by Scaleway and may be overwritten during auto-upgrades, we deploy [Envoy Gateway](https://gateway.envoyproxy.io/) (the CNCF reference implementation) as a standalone controller. All routing manifests use the portable Gateway API spec — if Scaleway enables Cilium Gateway API in the future, the implementation can be swapped with zero changes to route definitions.
- **External Secrets over sealed-secrets** — ESO integrates with Scaleway's Secret Manager, keeping secrets out of git entirely rather than encrypting them in-repo. Terragrunt seeds the initial secrets; ESO syncs them into the cluster.
- **Grafana Alloy over Promtail** — Alloy is Grafana's unified telemetry collector (successor to Promtail and Grafana Agent). A single DaemonSet collects logs today and will also collect traces when Tempo is added, eliminating the need for a separate OpenTelemetry Collector. Pragmatic choice: best integration with the Grafana stack (Loki, Tempo, Prometheus) while remaining open-source.
- **Crossplane provider auto-install** — The Scaleway provider is installed via the Crossplane Helm chart's `provider.packages` value rather than a separate Provider CR. This avoids the kustomize dry-run problem (Provider CR is a CRD instance that needs the Crossplane CRDs to exist first) and keeps the three-phase pattern clean.
- **Four-phase Flux reconciliation** — Operators (platform) → CRD instances like ClusterIssuer, ClusterSecretStore, ProviderConfig (platform-config) → Crossplane-managed cloud resources like S3 buckets and Container Registry (crossplane) → workloads (apps). Each phase `dependsOn` the previous one, avoiding Kustomize dry-run failures when CRDs don't exist yet. This "umbrella Kustomization per phase" is a deliberate simplification — at scale, each component would get its own Flux Kustomization with explicit per-component dependencies (DAG), trading readability for granular failure isolation and independent retries.

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
- [x] Secret Manager bootstrapping (Terragrunt seeds credentials consumed by ESO)

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
- [ ] Flux image automation (auto-deploy on new image tags)
- [ ] API auth token via ExternalSecret

### Phase 5 — Security Hardening 📋
Defense in depth — perimeter, internal, access control and audit:
- [ ] Kapsule API server allowed IPs (Crossplane `Acl` — restrict who can `kubectl` to the cluster)
- [ ] Security groups on Kapsule node pool (Terraform — restrict inbound/outbound at instance level)
- [ ] Edge Services WAF pipeline (Crossplane — OWASP CRS protection on public HTTP endpoints)
- [ ] Cilium NetworkPolicies (GitOps — default-deny per namespace, whitelist allowed pod-to-pod traffic)
- [ ] Pod Security Standards (GitOps — `enforce: restricted` or `baseline` labels on all namespaces)
- [ ] PodDisruptionBudgets (GitOps — protect workloads during Kapsule auto-upgrade node drains)
- [ ] Envoy Gateway rate limiting (GitOps — `BackendTrafficPolicy` to throttle abusive clients at L7)
- [ ] IAM least-privilege (Crossplane `Application` + `Policy` — scoped API keys per service instead of broad credentials)
- [ ] Audit Trail (Scaleway console — cloud-level logging of all API actions for compliance)
- [ ] RBAC hardening (namespace-scoped roles — relevant for multi-team production, optional for single-operator)

### Phase 6 — CI/CD 📋
- [ ] GitHub Actions pipeline (build, test, push image on commit)
- [ ] OIDC federation with Scaleway (no stored credentials)
