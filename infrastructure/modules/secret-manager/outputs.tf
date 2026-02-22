output "secret_id" {
  description = "ID of the secret."
  value       = scaleway_secret.this.id
}

output "secret_name" {
  description = "Name of the secret."
  value       = scaleway_secret.this.name
}
