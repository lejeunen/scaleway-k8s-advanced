variable "secrets" {
  description = "Map of secrets to create in Scaleway Secret Manager. Keys are secret names."
  type = map(object({
    description = optional(string)
    data        = string
  }))
  # Sensitivity is set at the field level via scaleway_secret_version.data,
  # not here — for_each cannot iterate over a sensitive variable.
}

variable "tags" {
  description = "Tags to associate with all secrets."
  type        = list(string)
  default     = []
}
