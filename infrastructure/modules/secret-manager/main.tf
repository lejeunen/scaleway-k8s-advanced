# State migration: single-resource → for_each
moved {
  from = scaleway_secret.this
  to   = scaleway_secret.this["scaleway-dns-credentials"]
}

moved {
  from = scaleway_secret_version.this
  to   = scaleway_secret_version.this["scaleway-dns-credentials"]
}

resource "scaleway_secret" "this" {
  for_each = var.secrets

  name        = each.key
  description = each.value.description
  tags        = var.tags
}

resource "scaleway_secret_version" "this" {
  for_each = var.secrets

  secret_id = scaleway_secret.this[each.key].id
  data      = each.value.data

  lifecycle {
    ignore_changes = [data]
  }
}
