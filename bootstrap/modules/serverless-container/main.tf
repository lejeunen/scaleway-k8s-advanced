locals {
  hostname = var.record_name == "" ? var.dns_zone : "${var.record_name}.${var.dns_zone}"
}

resource "scaleway_container_namespace" "this" {
  name   = var.namespace_name
  region = var.region
  tags   = var.tags
}

resource "scaleway_container" "this" {
  name                   = var.container_name
  namespace_id           = scaleway_container_namespace.this.id
  image                  = var.image
  port                   = var.port
  memory_limit_bytes     = var.memory_limit_bytes
  cpu_limit              = var.cpu_limit
  min_scale              = var.min_scale
  max_scale              = var.max_scale
  sandbox                = "v2"
  privacy                = "public"
  https_connections_only = true
  environment_variables  = var.environment_variables
  tags                   = var.tags
}

resource "scaleway_domain_record" "this" {
  dns_zone = var.dns_zone
  name     = var.record_name
  type     = var.record_name == "" ? "ALIAS" : "CNAME"
  data     = format("%s.", trimprefix(scaleway_container.this.public_endpoint, "https://"))
  ttl      = 300
}

resource "scaleway_container_domain" "this" {
  container_id = scaleway_container.this.id
  hostname     = local.hostname

  depends_on = [scaleway_domain_record.this]
}
