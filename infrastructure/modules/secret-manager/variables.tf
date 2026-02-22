variable "secret_name" {
  description = "Name of the secret in Scaleway Secret Manager."
  type        = string
}

variable "secret_data" {
  description = "The secret value to store."
  type        = string
  sensitive   = true
}

variable "description" {
  description = "Description of the secret."
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to associate with the secret."
  type        = list(string)
  default     = []
}
