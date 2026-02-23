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
  }
}
