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
│  │    Platform    │  │ Observability │  │  Crossplane  │  │
│  │   Components   │  │     Stack     │  │  Providers   │  │
│  │                │  │               │  │              │  │
│  │ Envoy Gateway  │  │ Prometheus    │  │ S3 Bucket    │  │
│  │  (Gateway API) │  │ Grafana       │  │ Container    │  │
│  │ cert-manager   │  │ Loki          │  │  Registry    │  │
│  │ External       │  │ Tempo         │  │              │  │
│  │   Secrets      │  │ Alloy         │  │ (Scaleway    │  │
│  │ CloudNativePG  │  │               │  │  Provider)   │  │
│  └────────────────┘  └───────────────┘  └──────────────┘  │
├───────────────────────────────────────────────────────────┤
│               Kapsule (Managed Kubernetes)                │
│                   VPC + Private Network                   │
├───────────────────────────────────────────────────────────┤
│            Terragrunt / Terraform (bootstrap)             │
└───────────────────────────────────────────────────────────┘
```

This project favors learning-by-doing: each commit is self-contained and tells a story. Browse the [commit history](https://github.com/lejeunen/scaleway-k8s-advanced/commits/main) for step-by-step implementation details.

## Key Design Decisions

- **Crossplane over pure Terraform** — Once the cluster exists, managing cloud resources as K8s custom resources keeps everything in a single control plane and reconciliation loop. No more split between "infra deploy" and "app deploy".
- **FluxCD over ArgoCD** — Flux follows a decentralized, pull-based model that fits well with a mono-repo layout. It's lighter-weight and doesn't require a UI or additional RBAC setup.
- **Terragrunt for bootstrap only** — Terraform/Terragrunt is the right tool for the initial chicken-and-egg problem (creating the cluster, seeding Secret Manager with credentials). After that, Crossplane takes over.
- **Gateway API over Ingress** — The Kubernetes [Gateway API](https://gateway-api.sigs.k8s.io/) is the successor to the Ingress resource, offering weighted traffic splitting (canary deployments), header-based routing, and cross-namespace references. Since `ingress-nginx` reaches [end-of-life in March 2026](https://kubernetes.io/blog/2025/11/11/ingress-nginx-retirement/), we use Gateway API from the start.
- **Envoy Gateway as Gateway API implementation** — Kapsule's managed Cilium supports Gateway API upstream, but Scaleway does not expose the `gatewayAPI.enabled` flag on managed clusters (as of Feb 2026). Since the Cilium installation in `kube-system` is managed by Scaleway and may be overwritten during auto-upgrades, we deploy [Envoy Gateway](https://gateway.envoyproxy.io/) (the CNCF reference implementation) as a standalone controller. All routing manifests use the portable Gateway API spec — if Scaleway enables Cilium Gateway API in the future, the implementation can be swapped with zero changes to route definitions.
- **External Secrets over sealed-secrets** — ESO integrates with Scaleway's Secret Manager, keeping secrets out of git entirely rather than encrypting them in-repo. Terragrunt seeds the initial secrets; ESO syncs them into the cluster.
- **Grafana Alloy over Promtail** — Alloy is Grafana's unified telemetry collector (successor to Promtail and Grafana Agent). A single DaemonSet collects logs today and will also collect traces when Tempo is added, eliminating the need for a separate OpenTelemetry Collector. Pragmatic choice: best integration with the Grafana stack (Loki, Tempo, Prometheus) while remaining open-source.
- **Crossplane provider auto-install** — The Scaleway provider is installed via the Crossplane Helm chart's `provider.packages` value rather than a separate Provider CR. This avoids the kustomize dry-run problem (Provider CR is a CRD instance that needs the Crossplane CRDs to exist first) and keeps the three-phase pattern clean.
- **Three-phase Flux reconciliation** — Operators (platform) → CRD instances like ClusterIssuer, ClusterSecretStore, and Crossplane ProviderConfig + managed resources (platform-config) → workloads (apps). This split avoids the Kustomize dry-run failure when CRDs don't exist yet on first deploy.

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

### Phase 4 — Application 🚀
Deploy [sovereign-cloud-wisdom](https://github.com/lejeunen/sovereign-cloud-wisdom) as a real workload:
- [ ] Dedicated Helm chart (in the app repo, simple and app-specific)
- [ ] CloudNativePG Cluster instance (app database, S3 backups via Crossplane bucket)
- [ ] ExternalSecrets for DB credentials and API auth token
- [ ] HTTPRoute on `wisdom.scw.sovereigncloudwisdom.eu`
- [ ] Grafana HTTPRoute on `grafana.scw.sovereigncloudwisdom.eu` (admin password moved to Secret Manager via ESO)
- [ ] Flux image automation (auto-deploy on new image tags)

### Phase 5 — CI/CD 📋
- [ ] GitHub Actions pipeline (build, test, push image on commit)
- [ ] OIDC federation with Scaleway (no stored credentials)
