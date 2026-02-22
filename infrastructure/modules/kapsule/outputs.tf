output "cluster_id" {
  description = "ID of the Kapsule cluster"
  value       = scaleway_k8s_cluster.this.id
}

output "cluster_url" {
  description = "Kubernetes API server URL"
  value       = scaleway_k8s_cluster.this.apiserver_url
}

output "kubeconfig" {
  description = "Kubeconfig for the cluster"
  value       = scaleway_k8s_cluster.this.kubeconfig
  sensitive   = true
}

output "wildcard_dns" {
  description = "Wildcard DNS of the cluster"
  value       = scaleway_k8s_cluster.this.wildcard_dns
}

output "pool_id" {
  description = "ID of the default node pool"
  value       = scaleway_k8s_pool.default.id
}