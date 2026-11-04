locals {
  name = "${var.project_name}-${var.environment}"

  artifact_bucket_name = lower(replace("${local.name}-artifacts-${data.aws_caller_identity.current.account_id}", "_", "-"))

  common_tags = merge(var.tags, {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  })
}

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
