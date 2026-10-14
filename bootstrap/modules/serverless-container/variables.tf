variable "namespace_name" {
  description = "Name of the Serverless Containers namespace"
  type        = string
}

variable "container_name" {
  description = "Name of the container"
  type        = string
}

variable "image" {
  description = "Image to deploy, with its tag"
  type        = string
}

variable "port" {
  description = "Port the container listens on"
  type        = number
}

variable "memory_limit_bytes" {
  description = "Memory in decimal bytes (256 MB = 256000000), must match cpu_limit per the provider's memory/vCPU table"
  type        = number
  default     = 256000000
}

variable "cpu_limit" {
  description = "vCPU in mvCPU (must match memory_limit_bytes)"
  type        = number
  default     = 140
}

variable "min_scale" {
  description = "Minimum number of instances (0 scales to zero when idle)"
  type        = number
  default     = 0
}

variable "max_scale" {
  description = "Maximum number of instances"
  type        = number
  default     = 1
}

variable "environment_variables" {
  description = "Environment variables of the container"
  type        = map(string)
  default     = {}
}

variable "dns_zone" {
  description = "DNS zone holding the custom domain record"
  type        = string
}

variable "record_name" {
  description = "Record name in the zone (empty for the zone apex, which uses an ALIAS record)"
  type        = string
  default     = ""
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
