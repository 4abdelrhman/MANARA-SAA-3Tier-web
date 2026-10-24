data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

locals {
  name = var.project_name
  azs  = slice(data.aws_availability_zones.available.names, 0, 2)

  public_subnets = {
    for index, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, index)
  }

  private_subnets = {
    for index, az in local.azs : az => cidrsubnet(var.vpc_cidr, 8, index + 10)
  }

  db_port        = var.db_engine == "postgres" ? 5432 : 3306
  app_port       = 80
  app_fqdn       = var.domain_name
  ssm_policy_arn = "arn:${data.aws_partition.current.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"

  custom_domain_enabled = var.domain_name != ""

  common_tags = merge(
    {
      Project   = var.project_name
      ManagedBy = "Terraform"
    },
    var.tags
  )
}
