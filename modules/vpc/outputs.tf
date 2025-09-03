output "vpc_id" {
  description = "The ID of the VPC."
  value       = aws_vpc.vpc.id

}

output "public_subnet_ids" {
  description = "List of public subnet IDs."
  value       = [for subnet in aws_subnet.subnet : subnet.id if subnet.map_public_ip_on_launch]

}

output "private_subnet_ids" {
  description = "List of private subnet IDs."
  value       = [for subnet in aws_subnet.subnet : subnet.id if !subnet.map_public_ip_on_launch]

}

output "app_security_group_id" {
  description = "The ID of the application security group."
  value       = aws_security_group.app_sg.id

}

output "db_security_group_id" {
  description = "The ID of the database security group."
  value       = aws_security_group.db_sg.id

}

output "web_security_group_id" {
  description = "The ID of the web security group."
  value       = aws_security_group.web_sg.id
}

output "subnet_group_db" {
  description = "The subnet group for the RDS instance."
  value       = aws_db_subnet_group.default.name
}
