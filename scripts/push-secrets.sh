#!/usr/bin/env bash
#
# Push secret values to Scaleway Secret Manager.
# Terraform manages secret shells (name/description/tags) only.
# This script pushes the actual sensitive data via the scw CLI,
# keeping it out of Terraform state.
#
# Usage:
#   source .env && ./scripts/push-secrets.sh [--dry-run] [SECRET_NAME...]
#
# If no secret names are given, all secrets are pushed.
# With --dry-run, prints what would be pushed without doing it.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

DRY_RUN=false
SELECTED=()

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=true ;;
    *) SELECTED+=("$arg") ;;
  esac
done

# Validate required env vars exist
require_env() {
  for var in "$@"; do
    if [[ -z "${!var:-}" ]]; then
      echo "ERROR: missing env var $var" >&2
      exit 1
    fi
  done
}

# Push a secret version. Creates a new version each time (ESO reads latest).
push_secret() {
  local name="$1"
  local data="$2"

  if $DRY_RUN; then
    echo "[dry-run] would push: $name"
    return
  fi

  echo "pushing: $name"
  scw secret version create \
    "$(scw secret secret list name="$name" -o json | jq -r '.[0].id')" \
    data="$data" \
    disable-previous=true \
    -o json > /dev/null
}

should_push() {
  local name="$1"
  if [[ ${#SELECTED[@]} -eq 0 ]]; then
    return 0
  fi
  for s in "${SELECTED[@]}"; do
    [[ "$s" == "$name" ]] && return 0
  done
  return 1
}

# --- Secret definitions ---
# Each secret's JSON payload mirrors what was previously in terragrunt.hcl

push_all() {
  # IAM scoped API keys (created via: scw iam api-key create application-id=<id>)
  # Application IDs: kubectl get applications.iam.scaleway.upbound.io -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.atProvider.id}{"\n"}{end}'

  if should_push "scaleway-dns-credentials"; then
    require_env DNS_MANAGER_ACCESS_KEY DNS_MANAGER_SECRET_KEY
    push_secret "scaleway-dns-credentials" "$(jq -nc \
      --arg ak "$DNS_MANAGER_ACCESS_KEY" --arg sk "$DNS_MANAGER_SECRET_KEY" \
      '{"access-key": $ak, "secret-key": $sk}')"
  fi

  if should_push "scaleway-crossplane-credentials"; then
    require_env SCW_ACCESS_KEY SCW_SECRET_KEY SCW_DEFAULT_PROJECT_ID SCW_REGION
    push_secret "scaleway-crossplane-credentials" "$(jq -nc \
      --arg ak "$SCW_ACCESS_KEY" --arg sk "$SCW_SECRET_KEY" \
      --arg pid "$SCW_DEFAULT_PROJECT_ID" --arg region "$SCW_REGION" \
      '{"access_key": $ak, "secret_key": $sk, "project_id": $pid, "region": $region}')"
  fi

  if should_push "grafana-admin-credentials"; then
    require_env GRAFANA_ADMIN_PASSWORD
    push_secret "grafana-admin-credentials" "$(jq -nc \
      --arg pw "$GRAFANA_ADMIN_PASSWORD" \
      '{"admin-user": "admin", "admin-password": $pw}')"
  fi

  if should_push "cnpg-s3-credentials"; then
    require_env CNPG_BACKUP_ACCESS_KEY CNPG_BACKUP_SECRET_KEY
    push_secret "cnpg-s3-credentials" "$(jq -nc \
      --arg ak "$CNPG_BACKUP_ACCESS_KEY" --arg sk "$CNPG_BACKUP_SECRET_KEY" \
      '{"ACCESS_KEY_ID": $ak, "ACCESS_SECRET_KEY": $sk}')"
  fi

  if should_push "matomo-mariadb-credentials"; then
    require_env MATOMO_ADMIN_PASSWORD
    push_secret "matomo-mariadb-credentials" "$(jq -nc \
      --arg pw "$MATOMO_ADMIN_PASSWORD" \
      '{"password": $pw, "root-password": $pw}')"
  fi

  if should_push "matomo-token-auth"; then
    require_env MATOMO_TOKEN_AUTH
    push_secret "matomo-token-auth" "$(jq -nc \
      --arg t "$MATOMO_TOKEN_AUTH" \
      '{"token": $t}')"
  fi

  if should_push "wisdom-api-auth-token"; then
    require_env WISDOM_API_AUTH_TOKEN
    push_secret "wisdom-api-auth-token" "$(jq -nc \
      --arg t "$WISDOM_API_AUTH_TOKEN" \
      '{"token": $t}')"
  fi

  if should_push "wisdom-registry-credentials"; then
    require_env SCW_SECRET_KEY
    push_secret "wisdom-registry-credentials" "$(jq -nc \
      --arg sk "$SCW_SECRET_KEY" \
      '{"auths": {"rg.fr-par.scw.cloud": {"username": "nologin", "password": $sk}}}')"
  fi

  if should_push "mistral-api-credentials"; then
    require_env MISTRAL_API_KEY
    push_secret "mistral-api-credentials" "$(jq -nc \
      --arg k "$MISTRAL_API_KEY" \
      '{"MISTRAL_API_KEY": $k}')"
  fi

  if should_push "jeanne-matrix-credentials"; then
    require_env JEANNE_MATRIX_ACCESS_TOKEN
    push_secret "jeanne-matrix-credentials" "$(jq -nc \
      --arg t "$JEANNE_MATRIX_ACCESS_TOKEN" \
      '{"MATRIX_USER_ID": "@jeanne:sovereigncloudwisdom.eu", "MATRIX_ACCESS_TOKEN": $t}')"
  fi

  if should_push "openclaw-github-app"; then
    require_env GITHUB_APP_ID GITHUB_APP_INSTALLATION_ID GITHUB_APP_PRIVATE_KEY
    push_secret "openclaw-github-app" "$(jq -nc \
      --arg id "$GITHUB_APP_ID" --arg iid "$GITHUB_APP_INSTALLATION_ID" \
      --arg pk "$GITHUB_APP_PRIVATE_KEY" \
      '{"APP_ID": $id, "INSTALLATION_ID": $iid, "PRIVATE_KEY": $pk}')"
  fi

  if should_push "jeanne-scaleway-credentials"; then
    require_env JEANNE_SCW_ACCESS_KEY JEANNE_SCW_SECRET_KEY
    push_secret "jeanne-scaleway-credentials" "$(jq -nc \
      --arg ak "$JEANNE_SCW_ACCESS_KEY" --arg sk "$JEANNE_SCW_SECRET_KEY" \
      '{"SCW_ACCESS_KEY": $ak, "SCW_SECRET_KEY": $sk}')"
  fi
}

push_all
echo "done."
