resource "scaleway_secret" "this" {
  name        = var.secret_name
  description = var.description
  tags        = var.tags
}

resource "scaleway_secret_version" "this" {
  secret_id = scaleway_secret.this.id
  data      = var.secret_data

  lifecycle {
    ignore_changes = [data]
  }
}
