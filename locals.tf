locals {
  create_nat = anytrue([for s in var.subnets : s.require_nat])
}
