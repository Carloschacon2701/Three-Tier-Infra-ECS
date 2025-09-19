
variable "app_image" {
  description = "ECR image for the application"
  type        = string
  default     = ""

  validation {
    condition     = length(var.app_image) > 0
    error_message = "The app_image cannot be empty."
  }
}



variable "env_variables" {
  description = "Environment variables for the application"
  type        = map(string)
  default     = {}

}

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
