resource "aws_db_subnet_group" "this" {
  name        = "meal_tracker_db_subnet_group"
  description = "Subnet group for RDS instances"

  subnet_ids = [
    for subnet in aws_subnet.meal_tracker_subnet :
    subnet.id
    if lookup(subnet.tags_all, "Type", "") == "db"
  ]
  tags = {
    Name = "meal_tracker_db_subnet_group"
  }
}

resource "aws_db_instance" "this" {
  allocated_storage    = 20
  db_name              = "mydb"
  engine               = "postgresql"
  engine_version       = "16.6"
  instance_class       = "db.t3.micro"
  username             = "foo"
  password             = "foobarbaz"
  parameter_group_name = "default.postgresql13"
  skip_final_snapshot  = true
  storage_type         = "gp2"
  identifier           = "meal-tracker-db-instance"
  network_type         = "IPV4"

  db_subnet_group_name = "meal_tracker_db_subnet_group"
  port                 = 5432
  vpc_security_group_ids = [
    for subnet in aws_subnet.meal_tracker_subnet :
    subnet.id
    if lookup(subnet.tags_all, "Type", "") == "db"
  ]

  publicly_accessible = false

}


