variable "default_tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}

}

variable "subnets" {
  description = "List of subnet"
  type = list(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
    require_nat       = bool
    type              = string

  }))

  validation {
    condition     = alltrue([for s in var.subnets : s.type == "app" || s.type == "web" || s.type == "db"])
    error_message = "Each subnet type must be one of 'app', 'web', or 'db'."
  }

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be defined."
  }

  validation {
    condition     = alltrue([for s in var.subnets : s.availability_zone != ""])
    error_message = "All subnets must have a valid availability zone."
  }

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrhost(s.cidr_block, 0))])
    error_message = "All subnets must have a valid CIDR block."
  }



}
