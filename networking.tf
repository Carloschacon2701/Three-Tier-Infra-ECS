############################################
# VPC MODULE
############################################
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

############################################
# ALB MODULE (HTTP ONLY)
############################################
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  name    = "${var.project_name}-alb"
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
    Project     = "${var.project_name}"
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
