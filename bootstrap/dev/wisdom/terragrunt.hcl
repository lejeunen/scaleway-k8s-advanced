include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "../../modules/serverless-container"
}

inputs = {
  namespace_name = "wisdom"
  container_name = "sovereign-cloud-wisdom"
  image          = "rg.fr-par.scw.cloud/sovereign-cloud-wisdom/sovereign-cloud-wisdom:20261014132359-b969216"
  port           = 8000
  environment_variables = {
    DATABASE_URL          = "sqlite+aiosqlite:////tmp/wisdom.db"
    CLOUD_PROVIDER        = "scw-advanced"
    OTEL_TRACES_EXPORTER  = "none"
    OTEL_METRICS_EXPORTER = "none"
    OTEL_LOGS_EXPORTER    = "none"
  }
  dns_zone    = "sovereigncloudwisdom.eu"
  record_name = ""
  region      = local.env.locals.region
  tags        = local.env.locals.tags
}
