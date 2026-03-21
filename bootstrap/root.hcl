remote_state {
  backend = "s3"

  config = {
    bucket     = "scaleway-k8s-advanced"
    key        = "${path_relative_to_include()}/terraform.tfstate"
    region     = "fr-par"
    encrypt    = false
    access_key = get_env("SCW_ACCESS_KEY")
    secret_key = get_env("SCW_SECRET_KEY")

    endpoints = {
      s3 = "https://s3.fr-par.scw.cloud"
    }

    skip_credentials_validation = true
    skip_region_validation      = true
    skip_bucket_versioning      = true
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    skip_s3_checksum            = true
  }

  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
}

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    scaleway = {
      source  = "scaleway/scaleway"
      version = "~> 2.69"
    }
  }
}

provider "scaleway" {
  region = "fr-par"
  zone   = "fr-par-1"
}
EOF
}

errors {
  retry "transient_errors" {
    retryable_errors = [
      "(?s).*Failed to load state.*tcp.*timeout.*",
      "(?s).*Error installing provider.*TLS handshake timeout.*",
      "(?s).*Error installing provider.*tcp.*timeout.*",
      "(?s).*Error installing provider.*tcp.*connection reset by peer.*",
      "(?s).*Client.Timeout exceeded while awaiting headers.*",
      "(?s).*429 Too Many Requests.*",
    ]
    max_attempts       = 3
    sleep_interval_sec = 5
  }
}