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
  secret_name = "scaleway-dns-credentials"
  description = "Scaleway API credentials for cert-manager DNS-01 solver"
  tags        = local.env.locals.tags

  secret_data = jsonencode({
    "access-key" = get_env("SCW_ACCESS_KEY")
    "secret-key" = get_env("SCW_SECRET_KEY")
  })
}
