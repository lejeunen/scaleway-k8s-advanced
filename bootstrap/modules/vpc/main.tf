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