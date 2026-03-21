output "vpc_id" {
  description = "ID of the VPC"
  value       = scaleway_vpc.this.id
}

output "private_network_id" {
  description = "ID of the private network"
  value       = scaleway_vpc_private_network.this.id
}