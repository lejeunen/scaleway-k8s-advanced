# Refactoring: 4-phase to DAG-based GitOps (DONE)

## Problem

The 4-phase pattern (platform -> platform-config -> crossplane -> apps) failed on fresh cluster bootstrap.
Each phase was a single Flux Kustomization that applied all resources at once. Kustomize dry-run rejected
CRD instances (ExternalSecret, Certificate, GatewayClass) when their CRDs didn't exist yet, even though
the HelmRelease that installed those CRDs was in the same phase.

## Solution

Replaced the 4 monolithic phases with per-component Flux Kustomizations, each with explicit `dependsOn`.
Follows the EMAsphere pattern: `system.yaml` scans `system/dev/` recursively, each component directory
creates its own Flux Kustomization(s) pointing to `system/base/<component>`.

## Structure

```
clusters/dev/
  flux-instance.yaml                    (bootstrap, applied manually)
  system.yaml                           (Flux Kustomization -> system/dev/, recursive scan)
  apps.yaml                             (Flux Kustomization -> apps/dev/)

system/base/                            (component manifests: HelmRelease, namespace, CRD instances, etc.)
  cert-manager/
  cert-manager-scaleway-webhook/
  cert-manager-issuer/
  external-secrets/
  external-secrets-store/
  envoy-gateway/
  envoy-gateway-config/
  cloudnative-pg/
  plugin-barman-cloud/
  crossplane/
  crossplane-config/
  crossplane-infra/
  loki/
  alloy/
  tempo/
  kube-prometheus-stack/
  external-dns/
  flux-web-ui/

system/dev/                             (per-component Flux Kustomizations with dependsOn DAG)
  <component>/
    kustomization.yaml                  (kustomize: lists the Flux Kustomization file)
    <component>.yaml                    (Flux Kustomization with dependsOn and path to base)

apps/base/                              (application workloads, unchanged)
apps/dev/                               (app overlay, unchanged)
```

## DAG (dependency graph)

```
Tier 0 (no deps):
  cert-manager, external-secrets, envoy-gateway, cloudnative-pg,
  crossplane, loki, tempo

Tier 1:
  alloy                          -> loki
  cert-manager-scaleway-webhook  -> cert-manager
  plugin-barman-cloud            -> cert-manager
  external-secrets-store         -> external-secrets
  envoy-gateway-config           -> envoy-gateway

Tier 2:
  cert-manager-issuer            -> cert-manager, external-secrets-store
  external-dns                   -> external-secrets-store
  kube-prometheus-stack          -> external-secrets-store, envoy-gateway
  flux-web-ui                    -> external-secrets-store, envoy-gateway
  crossplane-config              -> crossplane, external-secrets-store
  image-automation               -> external-secrets-store

Tier 3:
  crossplane-infra               -> crossplane-config

Apps:
  apps                           -> envoy-gateway-config, crossplane-infra
```

## postBuild variables

Centralized in two entry points. Variables propagate to all child Flux Kustomizations.

- system.yaml: SCW_PROJECT_ID, SCW_REGION, CLUSTER_NAME, ACME_EMAIL, GOOGLE_OIDC_CLIENT_ID
- apps.yaml: SCW_REGION, CLUSTER_NAME, GOOGLE_OIDC_CLIENT_ID

## Key design decisions

- **No kustomization.yaml at system/dev/ root** - Flux scans recursively, no list to maintain
- **One Flux Kustomization per component** - independent failure/retry, explicit dependencies
- **Dev overlay via nested directory** - envoy-gateway-config has a dev-specific subdirectory with a patch for HTTPS Gateway listener
- **image-automation in system/dev/** - it's system infrastructure, not a separate phase
- **flux-instance.yaml stays in clusters/dev/** - bootstrap chicken-and-egg (Flux Operator installed via Helm, FluxInstance configures it)
