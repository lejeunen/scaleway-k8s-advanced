locals {
  environment = "dev"
  region      = "fr-par"
  zone        = "fr-par-1"
  project     = "scaleway-k8s-advanced"

  # VPC
  vpc_name             = "dev-vpc"
  private_network_name = "dev-private-network"
  ipv4_subnet          = "172.16.0.0/22"

  # Kapsule
  k8s_cluster_name                = "dev-kapsule"
  k8s_version                     = "1.35"
  k8s_cni                         = "cilium"
  k8s_node_type                   = "DEV1-L"
  k8s_pool_size                   = 1
  k8s_pool_min_size               = 1
  k8s_pool_max_size               = 3
  k8s_pool_autoscale              = true
  k8s_delete_additional_resources = true
  k8s_auto_upgrade                = true
  k8s_auto_upgrade_hour           = 3
  k8s_auto_upgrade_day            = "sunday"

  # Common tags
  tags = ["env:dev", "project:scaleway-k8s-advanced", "managed-by:terragrunt"]
}