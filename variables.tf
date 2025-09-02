variable "subnets" {
  description = "List of subnet"
  type = list(object({
    cidr_block        = string
    availability_zone = string
    public            = bool
    require_nat       = bool

  }))


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
