include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../modules/vpc"
}

inputs = {
  vpc_name             = local.env.locals.vpc_name
  private_network_name = local.env.locals.private_network_name
  ipv4_subnet          = local.env.locals.ipv4_subnet
  public_gateway_name  = local.env.locals.public_gateway_name
  public_gateway_type  = local.env.locals.public_gateway_type
  region               = local.env.locals.region
  zone                 = local.env.locals.zone
  tags                 = local.env.locals.tags
}