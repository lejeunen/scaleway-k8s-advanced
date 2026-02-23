output "secret_ids" {
  description = "Map of secret name → secret ID."
  value       = { for k, v in scaleway_secret.this : k => v.id }
}

output "secret_names" {
  description = "Map of secret name → secret name."
  value       = { for k, v in scaleway_secret.this : k => v.name }
}
