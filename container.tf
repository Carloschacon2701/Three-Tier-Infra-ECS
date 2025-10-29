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
