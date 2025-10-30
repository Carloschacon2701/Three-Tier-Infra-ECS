
#####################################
# APPLICATION VARIABLES
#####################################

#####################################
# ECR IMAGE
#####################################
variable "app_image" {
  description = "ECR image for the application"
  type        = string
  default     = ""

  validation {
    condition     = length(var.app_image) > 0
    error_message = "The app_image cannot be empty."
  }
}


#####################################
# ENVIRONMENT VARIABLES
#####################################
variable "env_variables" {
  description = "Environment variables for the application"
  type        = map(string)
  default     = {}

}

#####################################
# IAM ROLES
#####################################
variable "task_exec_iam_role_arn" {
  description = "ARN of the IAM role for ECS task execution"
  type        = string
  default     = ""

  validation {
    condition     = length(var.task_exec_iam_role_arn) > 0
    error_message = "The task_exec_iam_role_arn cannot be empty."
  }
}

variable "tasks_iam_role_arn" {
  description = "ARN of the IAM role for ECS tasks"
  type        = string
  default     = ""

  validation {
    condition     = length(var.tasks_iam_role_arn) > 0
    error_message = "The tasks_iam_role_arn cannot be empty."
  }
}

#####################################
# PROJECT NAME
#####################################
variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = ""

  validation {
    condition     = length(var.project_name) > 0
    error_message = "The project_name cannot be empty."
  }
}


#####################################
# RDS CREDENTIALS
#####################################
variable "rds_credentials" {
  description = "Credentials for the RDS instance"
  type = object({
    username = string
    password = string
  })
  default = {
    username = "meal_user"
    password = "Mealtracker1!"
  }

  # sensitive = true
  validation {
    condition = (
      length(var.rds_credentials.password) >= 8 &&
      length(regexall("[a-zA-Z]", var.rds_credentials.password)) > 0 &&
      length(regexall("[0-9]", var.rds_credentials.password)) > 0 &&
      length(regexall("[!@#$%^&*()]", var.rds_credentials.password)) > 0
    )
    error_message = "The RDS password must be at least 8 characters long and contain at least one letter, one number, and one special character (!@#$%^&*())"
  }

}

#####################################
# RDS INSTANCE CLASS
#####################################
variable "rds_instance_class" {
  type        = string
  description = "The instance class of the RDS instance"
  default     = "db.t3.micro"

  validation {
    condition     = contains(["db.t3.micro"], var.rds_instance_class)
    error_message = "The RDS instance class must be one of the following: db.t3.micro"
  }
}

#####################################
# RDS ALLOCATED STORAGE
#####################################
variable "rds_allocated_storage" {
  type        = number
  description = "The allocated storage of the RDS instance"
  default     = 10

  validation {
    condition     = var.rds_allocated_storage >= 5 && var.rds_allocated_storage <= 10
    error_message = "The RDS allocated storage must be between 5 and 10GB"
  }
}

#####################################
# RDS ENGINE
#####################################
variable "rds_engine" {
  type = object({
    engine               = string
    family               = string
    major_engine_version = string
  })
  default = {
    engine               = "postgres"
    family               = "postgres14"
    major_engine_version = "14"
  }
  description = "The engine of the RDS instance"

  validation {
    condition     = length(var.rds_engine.engine) > 0
    error_message = "The rds_engine.engine cannot be empty."
  }

  validation {
    condition     = length(var.rds_engine.family) > 0
    error_message = "The rds_engine.family cannot be empty."
  }

  validation {
    condition     = length(var.rds_engine.major_engine_version) > 0
    error_message = "The rds_engine.major_engine_version cannot be empty."
  }
}

#####################################
# RDS DEFAULT DB NAME
#####################################
variable "rds_default_db_name" {
  description = "Default database name for the RDS instance"
  type        = string
  default     = ""

  validation {
    condition     = length(var.rds_default_db_name) > 0
    error_message = "The rds_default_db_name cannot be empty."
  }
}


#####################################
# AMPLIFY VARIABLES
#####################################
variable "amplify_variables" {
  description = "Variables for the Amplify application"
  type        = map(string)
  default     = {}
}

variable "amplify_app_repository" {
  description = "Repository for the Amplify application"
  type = object({
    repository = string
    branch     = string
    token      = string
  })
  sensitive = true
  default = {
    repository = ""
    branch     = "main"
    token      = ""
  }

  validation {
    condition     = !var.create_amplify_app ? true : length(var.amplify_app_repository.repository) > 0
    error_message = "The amplify_app_repository cannot be empty."
  }

  validation {
    condition     = !var.create_amplify_app ? true : length(regexall("^[a-zA-Z0-9_.-]+$", var.amplify_app_repository.repository)) > 0
    error_message = "The amplify_app_repository must be a valid repository name."
  }

  validation {
    condition     = !var.create_amplify_app ? true : length(var.amplify_app_repository.token) > 0
    error_message = "The amplify_app_repository.token cannot be empty."
  }

}

variable "create_amplify_app" {
  description = "Whether to create the Amplify application"
  type        = bool
  default     = false

  validation {
    condition     = var.create_amplify_app ? true : var.create_amplify_app == false
    error_message = "The create_amplify_app must be a boolean."
  }
}
