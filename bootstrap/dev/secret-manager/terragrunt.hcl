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
    "jeanne-showcase-registry-credentials" = {
      description = "Docker config JSON for the showcase to pull released Jeanne artifacts from the jeanne-release CR project (read-only entitlement; password = the jeanne-showcase-registry-pull api-key secret)"
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
    "jeanne-genai-credentials" = {
      description = "Scaleway IAM secret key for Jeanne dev Generative APIs inference"
    }
    "jeanne-model" = {
      description = "Scaleway secret key for Jeanne dev model (Devstral) inference"
    }
    "jeanne-gateway" = {
      description = "OpenClaw gateway token for Jeanne dev agent"
    }
    "jeanne-msteams" = {
      description = "Entra app client secret for Jeanne dev Teams bot (tenant nlesrl, jeanne-bot); ESO syncs to jeanne-dev as MSTEAMS_APP_PASSWORD"
    }
    "jeanne-memory-luks" = {
      description = "LUKS passphrase for Jeanne dev encrypted memory volume; ESO syncs to jeanne-dev as encryptionPassphrase. NB unrotatable - rotating orphans the volume and all its snapshots."
    }
  }
}
