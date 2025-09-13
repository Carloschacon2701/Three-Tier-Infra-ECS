
variable "app_image" {
  description = "ECR image for the application"
  type        = string
  default     = ""

  validation {
    condition     = can(regex("^[a-z0-9]+([._-][a-z0-9]+)*$", var.app_image))
    error_message = "The app_image must be a valid ECR image name."
  }

  validation {
    condition     = length(var.app_image) > 0
    error_message = "The app_image cannot be empty."
  }
}
