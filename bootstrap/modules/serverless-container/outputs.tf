output "public_endpoint" {
  description = "Native endpoint of the container"
  value       = scaleway_container.this.public_endpoint
}

output "hostname" {
  description = "Custom domain bound to the container"
  value       = scaleway_container_domain.this.hostname
}
