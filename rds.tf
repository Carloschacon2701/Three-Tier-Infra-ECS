############################################
# RDS MODULE
############################################

module "db" {
  source = "terraform-aws-modules/rds/aws"

  identifier = "${var.project_name}-db"

  instance_use_identifier_prefix = true

  create_db_option_group    = false
  create_db_parameter_group = false


  engine               = var.rds_engine.engine
  engine_version       = var.rds_engine.major_engine_version
  family               = var.rds_engine.family
  major_engine_version = var.rds_engine.major_engine_version
  instance_class       = var.rds_instance_class

  allocated_storage = var.rds_allocated_storage

  db_name  = var.rds_default_db_name
  username = var.rds_credentials.username
  port     = 5432

  db_subnet_group_name   = module.vpc.subnet_group_db
  vpc_security_group_ids = [module.vpc.db_security_group_id]

  maintenance_window      = "Mon:00:00-Mon:03:00"
  backup_window           = "03:00-06:00"
  backup_retention_period = 0

  manage_master_user_password = false
  password                    = var.rds_credentials.password
  apply_immediately           = true

}


