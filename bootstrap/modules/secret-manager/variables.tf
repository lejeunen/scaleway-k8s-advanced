variable "secrets" {
  description = "Map of secret shells to create in Scaleway Secret Manager. Keys are secret names."
  type = map(object({
    description = optional(string)
  }))
}

variable "tags" {
  description = "Tags to associate with all secrets."
  type        = list(string)
  default     = []
}
