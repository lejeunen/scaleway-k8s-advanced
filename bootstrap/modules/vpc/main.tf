resource "scaleway_vpc" "this" {
  name   = var.vpc_name
  region = var.region
  tags   = var.tags
}

resource "scaleway_vpc_private_network" "this" {
  name   = var.private_network_name
  vpc_id = scaleway_vpc.this.id
  region = var.region
  tags   = var.tags

  ipv4_subnet {
    subnet = var.ipv4_subnet
  }
}

resource "scaleway_vpc_public_gateway" "this" {
  name = var.public_gateway_name
  type = var.public_gateway_type
  zone = var.zone
  tags = var.tags
}

resource "scaleway_ipam_ip" "gateway" {
  source {
    private_network_id = scaleway_vpc_private_network.this.id
  }
}

resource "scaleway_vpc_gateway_network" "this" {
  gateway_id         = scaleway_vpc_public_gateway.this.id
  private_network_id = scaleway_vpc_private_network.this.id
  enable_masquerade  = true

  ipam_config {
    push_default_route = true
    ipam_ip_id         = scaleway_ipam_ip.gateway.id
  }
}