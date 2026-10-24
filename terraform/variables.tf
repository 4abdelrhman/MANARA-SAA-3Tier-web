variable "aws_region" {
  description = "AWS region used for the VPC, EC2, ALB, and RDS resources."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Short name used as the prefix for all resource names."
  type        = string
  default     = "scalable-webapp"

  validation {
    condition     = length(var.project_name) <= 20 && can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.project_name))
    error_message = "project_name must be 2-20 lowercase letters, numbers, or hyphens, and cannot start or end with a hyphen."
  }
}

variable "domain_name" {
  description = "Public DNS name for the application (for example, app.example.com). Leave empty to deploy without a custom domain and use the CloudFront domain instead."
  type        = string
  default     = ""

  validation {
    condition     = var.domain_name == "" || can(regex("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?)+$", var.domain_name))
    error_message = "domain_name must be an empty string or a valid lowercase DNS name such as app.example.com."
  }
}

variable "hosted_zone_id" {
  description = "Route 53 public hosted zone ID that contains domain_name. Required only when domain_name is set."
  type        = string
  default     = ""

  validation {
    condition     = var.hosted_zone_id == "" || can(regex("^Z[A-Z0-9]+$", var.hosted_zone_id))
    error_message = "hosted_zone_id must be empty or a valid Route 53 hosted zone ID."
  }
}

variable "alarm_email" {
  description = "Email address subscribed to the CloudWatch alarm SNS topic. Leave empty to skip the subscription."
  type        = string
  default     = ""

  validation {
    condition     = var.alarm_email == "" || can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.alarm_email))
    error_message = "alarm_email must be a valid email address or an empty string."
  }
}

variable "vpc_cidr" {
  description = "IPv4 CIDR block for the VPC. A /16 is recommended because the configuration derives /24 subnets from it."
  type        = string
  default     = "10.0.0.0/16"

  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0)) && tonumber(split("/", var.vpc_cidr)[1]) == 16
    error_message = "vpc_cidr must be a valid IPv4 /16 CIDR block."
  }
}

variable "instance_type" {
  description = "EC2 instance type used by the Auto Scaling group."
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of web instances."
  type        = number
  default     = 2
}

variable "asg_desired_capacity" {
  description = "Initial desired number of web instances. Autoscaling manages this value after creation."
  type        = number
  default     = 2
}

variable "asg_max_size" {
  description = "Maximum number of web instances."
  type        = number
  default     = 4
}

variable "db_engine" {
  description = "RDS engine. Supported values are mysql and postgres."
  type        = string
  default     = "mysql"

  validation {
    condition     = contains(["mysql", "postgres"], var.db_engine)
    error_message = "db_engine must be either mysql or postgres."
  }
}

variable "db_engine_version" {
  description = "RDS engine version. Change this together with db_engine when selecting PostgreSQL."
  type        = string
  default     = "8.0"
}

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name created by RDS."
  type        = string
  default     = "appdb"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,62}$", var.db_name))
    error_message = "db_name must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "db_username" {
  description = "RDS master username. The password is generated and managed by RDS in Secrets Manager."
  type        = string
  default     = "appadmin"

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]{0,15}$", var.db_username))
    error_message = "db_username must start with a letter and contain only letters, numbers, and underscores."
  }
}

variable "db_allocated_storage" {
  description = "Initial RDS storage in GiB."
  type        = number
  default     = 20
}

variable "db_max_allocated_storage" {
  description = "Maximum storage in GiB for RDS storage autoscaling."
  type        = number
  default     = 100
}

variable "rds_deletion_protection" {
  description = "Enable RDS deletion protection. Set to false only when intentionally destroying the environment."
  type        = bool
  default     = true
}

variable "rds_skip_final_snapshot" {
  description = "Skip the final RDS snapshot on deletion. Set to true only for disposable environments."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Additional tags applied to all resources."
  type        = map(string)
  default     = {}
}
