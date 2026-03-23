variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "private_network_name" {
  description = "Name of the private network"
  type        = string
}

variable "ipv4_subnet" {
  description = "IPv4 CIDR block for the private network"
  type        = string
  default     = "172.16.0.0/22"
}

variable "region" {
  description = "Scaleway region"
  type        = string
}

variable "zone" {
  description = "Scaleway zone for zonal resources (Public Gateway)"
  type        = string
}

variable "public_gateway_name" {
  description = "Name of the Public Gateway"
  type        = string
}

variable "public_gateway_type" {
  description = "Public Gateway type (VPC-GW-S, VPC-GW-M, VPC-GW-L)"
  type        = string
  default     = "VPC-GW-S"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = []
}