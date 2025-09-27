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
      require_nat       = true
      type              = "db"
    },
    {
      cidr_block        = "10.0.40.0/24"
      availability_zone = "us-east-1b"
      public            = false
      require_nat       = true
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



}

module "ecs" {
  source  = "terraform-aws-modules/ecs/aws"
  version = "6.3.0"

  # Cluster Configuration
  cluster_name = "meal-tracker-cluster"

  cluster_configuration = {
    execute_command_configuration = {
      logging = "OVERRIDE"
      log_configuration = {
        cloud_watch_log_group_name = "/aws/ecs/meal_tracker"
      }
    }
  }

  # Capacity Providers
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 20
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }

  # Services with Task Definitions
  services = {
    # Service 2: Backend API Service
    backend_api = {
      # Task Definition Configuration
      cpu                = 1024
      memory             = 2048
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

          # Environment variables
          environment = concat([for key, value in var.env_variables : {
            name  = key
            value = value
            }], [
            {
              name  = "DB_URL"
              value = "jdbc:postgresql://${module.db.db_instance_endpoint}:${module.db.db_instance_port}/${module.db.db_instance_name}"
            },
            {
              name  = "DB_SECRET_ARN"
              value = module.db.db_instance_master_user_secret_arn
            }
          ])

          # Health check
          health_check = {
            command      = ["CMD-SHELL", "curl -f http://localhost:8080/health || exit 1"]
            interval     = 30
            timeout      = 5
            retries      = 3
            start_period = 60
          }

          # Linux parameters
          linux_parameters = {
            init_process_enabled = true
          }

          enable_cloudwatch_logging = true
        }

        # # Database migration sidecar (runs once)
        # db_migrate = {
        #   cpu       = 512
        #   memory    = 1024
        #   essential = false
        #   image     = "my-company/db-migrations:v1.2.3"

        #   depends_on = [
        #     {
        #       containerName = "api"
        #       condition     = "START"
        #     }
        #   ]
        # }
      }

      # Service Configuration
      desired_count = 1
      launch_type   = "FARGATE"
      iam_role_arn  = var.task_exec_iam_role_arn

      # Network Configuration
      subnet_ids       = module.vpc.app_subnets_ids
      assign_public_ip = false

      # Container mount points for the volume
      # container_definitions = {
      #   api = {
      #     # ... other container config ...
      #     mount_points = [
      #       {
      #         sourceVolume  = "shared-data"
      #         containerPath = "/app/shared"
      #         readOnly      = false
      #       }
      #     ]
      #   }
      # }

      # Placement constraints

      task_exec_iam_role_arn = var.task_exec_iam_role_arn
      # Custom IAM permissions for task role
      tasks_iam_role_arn = var.tasks_iam_role_arn
    }

  }

}
