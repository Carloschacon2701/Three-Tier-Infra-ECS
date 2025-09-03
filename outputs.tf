output "vpc_id" {
  description = "The ID of the VPC."
  value       = module.vpc.vpc_id

}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = module.vpc.public_subnet_ids

}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = module.vpc.private_subnet_ids

}

output "app_security_group_id" {
  description = "The ID of the application security group."
  value       = module.vpc.app_security_group_id

}

output "db_security_group_id" {
  description = "The ID of the database security group."
  value       = module.vpc.db_security_group_id

}

output "web_security_group_id" {
  description = "The ID of the web security group."
  value       = module.vpc.web_security_group_id

}

output "db_instance_endpoint" {
  description = "The endpoint of the RDS instance."
  value       = module.db.db_instance_endpoint

}

output "db_instance_port" {
  description = "The port of the RDS instance."
  value       = module.db.db_instance_port

}

output "db_instance_identifier" {
  description = "The identifier of the RDS instance."
  value       = module.db.db_instance_identifier

}
