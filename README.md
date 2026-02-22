# Scaleway K8s Advanced

[![GitHub](https://img.shields.io/badge/GitHub-lejeunen%2Fscaleway--k8s--advanced-blue?logo=github)](https://github.com/lejeunen/scaleway-k8s-advanced)

Building on the foundations of [scaleway-starter-kit](https://github.com/lejeunen/scaleway-starter-kit), this project takes a **Kubernetes-first** approach to sovereign cloud infrastructure on Scaleway.

## Why Sovereign Cloud?

European regulations (GDPR, upcoming EUCS certification) increasingly require that data stays within EU borders, processed by EU-headquartered providers. Scaleway, as a French cloud provider with datacenters in Paris and Amsterdam, offers a credible alternative to US hyperscalers for organizations that need **data sovereignty** without sacrificing modern cloud-native tooling.

This project demonstrates that a production-grade Kubernetes platform can be built entirely on sovereign infrastructure — portable enough to move between providers, yet fully leveraging Scaleway's managed services.

## The Approach

Bootstrap a Kapsule cluster with Terraform/Terragrunt, then manage everything else — cloud resources included — through GitOps (FluxCD) and Crossplane. This design maximizes multi-cloud portability by expressing infrastructure as Kubernetes resources rather than provider-specific IaC.

```
┌─────────────────────────────────────────────────────────┐
│                    GitOps (FluxCD)                       │
│         Declarative, git-driven reconciliation          │
│                                                         │
│  ┌──────────────┐  ┌─────────────┐  ┌───────────────┐  │
│  │   Platform    │  │ Observability│  │  Crossplane   │  │
│  │  Components   │  │    Stack    │  │   Providers   │  │
│  │              │  │             │  │               │  │
│  │ NGINX Ingress│  │ Prometheus  │  │ RDB Instances │  │
│  │ cert-manager │  │ Grafana     │  │ Registry      │  │
│  │ External     │  │ Loki        │  │ Secret Manager│  │
│  │  Secrets     │  │             │  │               │  │
│  └──────────────┘  └─────────────┘  └───────────────┘  │
├─────────────────────────────────────────────────────────┤
│              Kapsule (Managed Kubernetes)                │
│              VPC + Private Network                      │
├─────────────────────────────────────────────────────────┤
│           Terragrunt / Terraform (bootstrap)            │
└─────────────────────────────────────────────────────────┘
```

This project favors learning-by-doing: each commit is self-contained and tells a story. Browse the [commit history](https://github.com/lejeunen/scaleway-k8s-advanced/commits/main) for step-by-step implementation details.

## Key Design Decisions

- **Crossplane over pure Terraform** — Once the cluster exists, managing cloud resources as K8s custom resources keeps everything in a single control plane and reconciliation loop. No more split between "infra deploy" and "app deploy".
- **FluxCD over ArgoCD** — Flux follows a decentralized, pull-based model that fits well with a mono-repo layout. It's lighter-weight and doesn't require a UI or additional RBAC setup.
- **Terragrunt for bootstrap only** — Terraform/Terragrunt is the right tool for the initial chicken-and-egg problem (creating the cluster that will host everything else). After that, Crossplane takes over.
- **External Secrets over sealed-secrets** — ESO integrates with Scaleway's Secret Manager, keeping secrets out of git entirely rather than encrypting them in-repo.

## Prerequisites

- [Scaleway account](https://console.scaleway.com/) with API keys configured
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Terragrunt](https://terragrunt.gruntwork.io/docs/getting-started/install/) >= 0.50
- [kubectl](https://kubernetes.io/docs/tasks/tools/)
- [Flux CLI](https://fluxcd.io/flux/installation/#install-the-flux-cli)

## Roadmap

### Phase 1 — Foundation ✅
Terragrunt-managed infrastructure to get a production-ready Kapsule cluster:
- VPC with private network
- Kapsule cluster with autoscaling node pool
- Automatic K8s version upgrades (Sunday 3am maintenance window)
- PodSecurity enforcement via namespace labels (Kapsule enables the [PodSecurity admission controller](https://kubernetes.io/docs/concepts/security/pod-security-admission/) by default)
- Environment-aware safety: `delete_additional_resources` protects production from accidental resource deletion

### Phase 2 — GitOps 🔧
FluxCD bootstrap to manage all subsequent components declaratively:
- Ingress controller (NGINX)
- TLS automation (cert-manager)
- Secret management (External Secrets Operator)
- Observability stack

### Phase 3 — Crossplane 📋
Cloud resources as Kubernetes custom resources:
- Managed databases
- Container registry
- Secret Manager
- Full lifecycle management through the K8s control plane
