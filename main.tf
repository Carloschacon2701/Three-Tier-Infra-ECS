
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

module "ecs_cluster" {
  source = "terraform-aws-modules/ecs/aws"

  cluster_name = "meal-tracker-cluster"

  # Capacity provider
  default_capacity_provider_strategy = {
    FARGATE = {
      weight = 50
      base   = 20
    }
    FARGATE_SPOT = {
      weight = 50
    }
  }

  # services = {
  #   melat_tracker_backend = {
  #     cpu    = 1024
  #     memory = 4096

  #     ecs-sample = {
  #       cpu       = 512
  #       memory    = 1024
  #       essential = true
  #       image     = "public.ecr.aws/aws-containers/ecsdemo-frontend:776fd50"
  #       portMappings = [
  #         {
  #           name          = "ecs-sample"
  #           containerPort = 80
  #           protocol      = "tcp"
  #         }
  #       ]

  #       readonlyRootFilesystem = false
  #       memoryReservation      = 100
  #     }
  #   }
  # }


}
