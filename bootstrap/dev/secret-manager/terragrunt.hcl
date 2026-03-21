include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../modules/secret-manager"
}

inputs = {
  tags = local.env.locals.tags

  secrets = {
    "scaleway-dns-credentials" = {
      description = "Scaleway API credentials for cert-manager DNS-01 solver"
    }
    "scaleway-crossplane-credentials" = {
      description = "Scaleway API credentials for Crossplane provider"
    }
    "grafana-admin-credentials" = {
      description = "Grafana admin credentials"
    }
    "cnpg-s3-credentials" = {
      description = "S3 credentials for CNPG barman-cloud backups"
    }
    "matomo-mariadb-credentials" = {
      description = "MariaDB credentials for Matomo"
    }
    "matomo-token-auth" = {
      description = "Matomo auth token for server-side tracking"
    }
    "wisdom-api-auth-token" = {
      description = "Bearer token for sovereign-cloud-wisdom write API"
    }
    "wisdom-registry-credentials" = {
      description = "Docker config JSON for pulling sovereign-cloud-wisdom images"
    }
    "mistral-api-credentials" = {
      description = "Mistral API key for OpenClaw agent Jeanne"
    }
    "jeanne-matrix-credentials" = {
      description = "Matrix credentials for OpenClaw agent Jeanne"
    }
    "openclaw-github-app" = {
      description = "GitHub App credentials for OpenClaw agent Jeanne"
    }
    "jeanne-scaleway-credentials" = {
      description = "Scaleway read-only API credentials for Jeanne agent (scw CLI)"
    }
  }
}
