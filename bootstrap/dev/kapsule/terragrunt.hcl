include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../modules/kapsule"
}

dependency "vpc" {
  config_path = "../vpc"

  mock_outputs = {
    vpc_id             = "fr-par/00000000-0000-0000-0000-000000000000"
    private_network_id = "fr-par/00000000-0000-0000-0000-000000000000"
  }

  mock_outputs_merge_with_state           = true
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init", "destroy"]
}

inputs = {
  cluster_name                = local.env.locals.k8s_cluster_name
  cluster_type                = local.env.locals.k8s_cluster_type
  k8s_version                 = local.env.locals.k8s_version
  cni                         = local.env.locals.k8s_cni
  private_network_id          = dependency.vpc.outputs.private_network_id
  region                      = local.env.locals.region
  node_type                   = local.env.locals.k8s_node_type
  pool_size                   = local.env.locals.k8s_pool_size
  pool_min_size               = local.env.locals.k8s_pool_min_size
  pool_max_size               = local.env.locals.k8s_pool_max_size
  pool_autoscaling            = local.env.locals.k8s_pool_autoscale
  delete_additional_resources = local.env.locals.k8s_delete_additional_resources
  auto_upgrade_enabled        = local.env.locals.k8s_auto_upgrade
  auto_upgrade_hour           = local.env.locals.k8s_auto_upgrade_hour
  auto_upgrade_day            = local.env.locals.k8s_auto_upgrade_day
  tags                        = local.env.locals.tags
}