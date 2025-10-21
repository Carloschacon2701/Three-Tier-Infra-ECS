provider "aws" {
  region = "us-east-1"
  default_tags {
    tags = {
      Environment = "dev"
      owner       = "carlos"
      Project     = "meal_tracker"
    }
  }
}

module "vpc" {
  source = "./modules/vpc"

  subnets = [
    {
      cidr_block        = "10.0.1.0/24"
      availability_zone = "us-east-1a"
      public            = true
      require_nat       = false
      type              = "web"
    },
    {
      cidr_block        = "10.0.2.0/24"
      availability_zone = "us-east-1b"
      public            = true
      require_nat       = false
      type              = "web"
    },
    {
      cidr_block        = "10.0.10.0/24"
      availability_zone = "us-east-1a"
      public            = false
      require_nat       = true
      type              = "app"
    },
    {
      cidr_block        = "10.0.30.0/24"
      availability_zone = "us-east-1b"
      public            = false
      require_nat       = true
      type              = "app"
    },
    {
      cidr_block        = "10.0.20.0/24"
      availability_zone = "us-east-1a"
      public            = false
      require_nat       = false
      type              = "db"
    },
    {
      cidr_block        = "10.0.40.0/24"
      availability_zone = "us-east-1b"
      public            = false
      require_nat       = false
      type              = "db"
    }
  ]
}


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

############################################
# ALB MODULE (HTTP ONLY)
############################################
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "meal-tracker-alb"
  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.public_subnet_ids

  # Security Group
  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      description = "HTTP web traffic"
      cidr_ipv4   = "0.0.0.0/0"
    }
  }

  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = "10.0.0.0/16"
    }
  }

  # Listener: HTTP only
  listeners = {
    http = {
      port     = 80
      protocol = "HTTP"
      forward = {
        target_group_key = "backend_api_tg"
      }
    }
  }

  enable_deletion_protection = false

  # Target Group for ECS Fargate Tasks
  target_groups = {
    backend_api_tg = {
      name_prefix       = "api-"
      protocol          = "HTTP"
      port              = 80
      target_type       = "ip"
      create_attachment = false

      health_check = {
        path                = "/health/"
        interval            = 30
        timeout             = 5
        healthy_threshold   = 3
        unhealthy_threshold = 3
        matcher             = "200"
      }
    }
  }

  tags = {
    Environment = "Development"
    Project     = "MealTracker"
  }
}

############################################
# SECURITY GROUP RULE - ALB -> ECS SERVICE
############################################
resource "aws_security_group_rule" "alb_to_app" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = module.vpc.app_security_group_id
  source_security_group_id = module.alb.security_group_id
}

############################################
# ECS MODULE
############################################
module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.3.0"

  cluster_name = "meal-tracker-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/meal_tracker"
      }
    }
  }

  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 20
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }

  services = {
    backend_api = {
      cpu                = 1024
      memory             = 2048
      desired_count      = 1
      launch_type        = "FARGATE"
      iam_role_arn       = var.task_exec_iam_role_arn
      subnet_ids         = module.vpc.app_subnets_ids
      assign_public_ip   = false
      security_group_ids = [module.vpc.app_security_group_id]

      container_definitions = {
        api = {
          cpu       = 1024
          memory    = 2048
          essential = true
          image     = var.app_image

          portMappings = [
            {
              name          = "api"
              containerPort = 8080
              protocol      = "tcp"
            }
          ]

          environment = concat(
            [for key, value in var.env_variables : {
              name  = key
              value = value
            }],
            [
              {
                name  = "DB_URL"
                value = "jdbc:postgresql://${module.db.db_instance_endpoint}/${module.db.db_instance_name}"
              },
              {
                name  = "DB_PASSWORD"
                value = var.db_password
              }
            ]
          )

          health_check = {
            command      = ["CMD-SHELL", "curl -f http://localhost:8080/health/ || exit 1"]
            interval     = 30
            timeout      = 5
            retries      = 3
            start_period = 60
          }

          linux_parameters = {
            init_process_enabled = true
          }

          enable_cloudwatch_logging = true
        }
      }

      load_balancer = {
        backend_api_tg = {
          target_group_arn = module.alb.target_groups["backend_api_tg"].arn
          container_name   = "api"
          container_port   = 8080
        }
      }

      task_exec_iam_role_arn = var.task_exec_iam_role_arn
      tasks_iam_role_arn     = var.tasks_iam_role_arn
    }
  }

  depends_on = [module.alb]
}
