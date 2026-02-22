resource "scaleway_k8s_cluster" "this" {
  name               = var.cluster_name
  version            = var.k8s_version
  cni                = var.cni
  region             = var.region
  private_network_id = var.private_network_id
  tags               = var.tags

  delete_additional_resources = true

  auto_upgrade {
    enable                        = false
    maintenance_window_start_hour = 0
    maintenance_window_day        = "any"
  }

  autoscaler_config {
    disable_scale_down           = false
    scale_down_delay_after_add   = "5m"
    scale_down_unneeded_time     = "5m"
    estimator                    = "binpacking"
    expander                     = "random"
    ignore_daemonsets_utilization = true
    balance_similar_node_groups  = true
  }
}

resource "scaleway_k8s_pool" "default" {
  cluster_id  = scaleway_k8s_cluster.this.id
  name        = "${var.cluster_name}-default"
  node_type   = var.node_type
  size        = var.pool_size
  min_size    = var.pool_min_size
  max_size    = var.pool_max_size
  autoscaling = var.pool_autoscaling
  autohealing = true

  upgrade_policy {
    max_unavailable = 1
    max_surge       = 1
  }

  wait_for_pool_ready = true
}