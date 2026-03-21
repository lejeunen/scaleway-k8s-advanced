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

variable "tags" {
  description = "Tags to apply to resources"
  type        = list(string)
  default     = []
}