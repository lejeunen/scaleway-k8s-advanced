# Manages secret shells (name, description, tags) only.
# Secret values are pushed separately via scripts/push-secrets.sh
# to keep sensitive data out of Terraform state.

resource "scaleway_secret" "this" {
  for_each = var.secrets

  name        = each.key
  description = each.value.description
  tags        = var.tags
}
