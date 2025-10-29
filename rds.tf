############################################
# RDS MODULE
############################################
module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "meal-tracker-db"

  instance_use_identifier_prefix = true

  create_db_option_group    = false
  create_db_parameter_group = false


  engine               = "postgres"
  engine_version       = "14"
  family               = "postgres14"
  major_engine_version = "14"
  instance_class       = "db.t3.micro"

  allocated_storage = 20

  db_name  = "mealdb"
  username = "meal_user"
  port     = 5432

  db_subnet_group_name   = module.vpc.subnet_group_db
  vpc_security_group_ids = [module.vpc.db_security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0

  manage_master_user_password = false
  password                    = var.db_password

}
