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
      data = jsonencode({
        "access-key" = get_env("SCW_ACCESS_KEY")
        "secret-key" = get_env("SCW_SECRET_KEY")
      })
    }
    "scaleway-crossplane-credentials" = {
      description = "Scaleway API credentials for Crossplane provider"
      data = jsonencode({
        "access_key" = get_env("SCW_ACCESS_KEY")
        "secret_key" = get_env("SCW_SECRET_KEY")
        "project_id" = get_env("SCW_DEFAULT_PROJECT_ID")
        "region"     = local.env.locals.region
      })
    }
    "grafana-admin-credentials" = {
      description = "Grafana admin credentials"
      data = jsonencode({
        "admin-user"     = "admin"
        "admin-password" = get_env("GRAFANA_ADMIN_PASSWORD")
      })
    }
    "cnpg-s3-credentials" = {
      description = "S3 credentials for CNPG barman-cloud backups"
      data = jsonencode({
        "ACCESS_KEY_ID"     = get_env("SCW_ACCESS_KEY")
        "ACCESS_SECRET_KEY" = get_env("SCW_SECRET_KEY")
      })
    }
    "matomo-mariadb-credentials" = {
      description = "MariaDB credentials for Matomo"
      data = jsonencode({
        "password"      = get_env("MATOMO_ADMIN_PASSWORD")
        "root-password" = get_env("MATOMO_ADMIN_PASSWORD")
      })
    }
    "matomo-token-auth" = {
      description = "Matomo auth token for server-side tracking"
      data = jsonencode({
        "token" = get_env("MATOMO_TOKEN_AUTH")
      })
    }
    "wisdom-api-auth-token" = {
      description = "Bearer token for sovereign-cloud-wisdom write API"
      data = jsonencode({
        "token" = get_env("WISDOM_API_AUTH_TOKEN")
      })
    }
    "wisdom-registry-credentials" = {
      description = "Docker config JSON for pulling sovereign-cloud-wisdom images"
      data = jsonencode({
        auths = {
          "rg.fr-par.scw.cloud" = {
            username = "nologin"
            password = get_env("SCW_SECRET_KEY")
          }
        }
      })
    }
  }
}
