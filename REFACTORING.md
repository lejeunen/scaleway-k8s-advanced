# Refactoring: 4-phase to DAG-based GitOps

## Problem

The 4-phase pattern (platform -> platform-config -> crossplane -> apps) fails on fresh cluster bootstrap.
Each phase is a single Flux Kustomization that applies all resources at once. Kustomize dry-run rejects
CRD instances (ExternalSecret, Certificate, GatewayClass) when their CRDs don't exist yet, even though
the HelmRelease that installs those CRDs is in the same phase.

## Solution

Replace the 4 monolithic phases with per-component Flux Kustomizations, each with explicit `dependsOn`.
Follow the EMAsphere pattern: `system.yaml` scans `system/dev/` recursively, each component directory
creates its own Flux Kustomization(s) pointing to `system/base/<component>`.

## Target structure

```
clusters/dev/
  flux-instance.yaml                    (bootstrap, applied manually)
  system.yaml                           (Flux Kustomization -> system/dev/, recursive scan)
  apps.yaml                             (Flux Kustomization -> apps/dev/)

system/dev/
  cert-manager/
    kustomization.yaml                  (resources: cert-manager.yaml)
    cert-manager.yaml                   (Flux Kustomization -> system/base/cert-manager)
  cert-manager-scaleway-webhook/
    kustomization.yaml
    cert-manager-scaleway-webhook.yaml  (dependsOn: cert-manager)
  cert-manager-issuer/
    kustomization.yaml
    cert-manager-issuer.yaml            (dependsOn: cert-manager, external-secrets-store)
  external-secrets/
    kustomization.yaml
    external-secrets.yaml               (Flux Kustomization -> system/base/external-secrets)
  external-secrets-store/
    kustomization.yaml
    external-secrets-store.yaml         (dependsOn: external-secrets)
  envoy-gateway/
    kustomization.yaml
    envoy-gateway.yaml                  (Flux Kustomization -> system/base/envoy-gateway)
  envoy-gateway-config/
    kustomization.yaml
    envoy-gateway-config.yaml           (dependsOn: envoy-gateway)
    envoy-gateway-config/               (content with dev overlay/patch)
  cloudnative-pg/
    kustomization.yaml
    cloudnative-pg.yaml
  plugin-barman-cloud/
    kustomization.yaml
    plugin-barman-cloud.yaml            (dependsOn: cert-manager)
  crossplane/
    kustomization.yaml
    crossplane.yaml
  crossplane-config/
    kustomization.yaml
    crossplane-config.yaml              (dependsOn: crossplane, external-secrets-store)
  crossplane-infra/
    kustomization.yaml
    crossplane-infra.yaml               (dependsOn: crossplane-config)
  loki/
    kustomization.yaml
    loki.yaml
  alloy/
    kustomization.yaml
    alloy.yaml                          (dependsOn: loki)
  tempo/
    kustomization.yaml
    tempo.yaml
  kube-prometheus-stack/
    kustomization.yaml
    kube-prometheus-stack.yaml          (dependsOn: external-secrets-store)
  external-dns/
    kustomization.yaml
    external-dns.yaml                   (dependsOn: external-secrets-store)
  flux-web-ui/
    kustomization.yaml
    flux-web-ui.yaml
  image-automation/
    kustomization.yaml
    image-automation.yaml               (dependsOn: external-secrets-store)
    image-automation/                   (content: ImagePolicy, ImageRepository, etc.)

system/base/
  (all component manifests, one subdirectory each - moved from platform/base/ and platform-config/base/)
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
  crossplane-infra/                     (moved from crossplane/base/)
  loki/
  alloy/
  tempo/
  kube-prometheus-stack/
  external-dns/
  flux-web-ui/

apps/base/                              (unchanged)
apps/dev/                               (unchanged)
```

## DAG (dependency graph)

```
Tier 0 (no deps):
  cert-manager, external-secrets, envoy-gateway, cloudnative-pg,
  crossplane, loki, tempo, flux-web-ui

Tier 1:
  alloy                          -> loki (shared HelmRepository)
  cert-manager-scaleway-webhook  -> cert-manager
  plugin-barman-cloud            -> cert-manager
  external-secrets-store         -> external-secrets
  envoy-gateway-config           -> envoy-gateway

Tier 2:
  cert-manager-issuer            -> cert-manager, external-secrets-store
  external-dns                   -> external-secrets-store
  kube-prometheus-stack          -> external-secrets-store
  crossplane-config              -> crossplane, external-secrets-store

Tier 3:
  crossplane-infra               -> crossplane-config
  image-automation               -> external-secrets-store

Apps:
  apps                           -> envoy-gateway-config, crossplane-infra
```

## postBuild variables

All variables currently spread across platform.yaml, platform-config.yaml, crossplane.yaml, apps.yaml
will be centralized in system.yaml and apps.yaml. The `postBuild.substituteFrom` or direct `substitute`
in system.yaml propagates to all child Flux Kustomizations.

system.yaml: SCW_PROJECT_ID, SCW_REGION, CLUSTER_NAME, ACME_EMAIL, GOOGLE_OIDC_CLIENT_ID
apps.yaml:   SCW_REGION, CLUSTER_NAME, GOOGLE_OIDC_CLIENT_ID

## Execution steps

1. Create system/base/ - move all component directories from platform/base/, platform-config/base/, crossplane/base/
2. Create system/dev/ - one subdirectory per component with Flux Kustomization(s)
3. Handle envoy-gateway-config dev overlay (Gateway HTTPS patch)
4. Handle image-automation (move from clusters/dev/ to system/dev/)
5. Update clusters/dev/ - replace platform.yaml, platform-config.yaml, crossplane.yaml with system.yaml
6. Update clusters/dev/kustomization.yaml (flux-instance.yaml, system.yaml, apps.yaml)
7. Update apps.yaml dependsOn (envoy-gateway-config, crossplane-infra instead of crossplane)
8. Delete old directories: platform/, platform-config/, crossplane/
9. Update README.md (repository structure table, four-phase references)
10. Update MEMORY.md
11. Commit and push
12. Verify Flux reconciliation on the live cluster

## Deleted directories (after migration)

- gitops/platform/
- gitops/platform-config/
- gitops/crossplane/
