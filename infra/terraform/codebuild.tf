resource "aws_cloudwatch_log_group" "codebuild" {
  name              = "/codebuild/${local.name}"
  retention_in_days = 30
  tags              = local.common_tags
}

resource "aws_codebuild_project" "hauler" {
  name          = local.name
  description   = "Build Hauler haul from inventory and upload to S3"
  service_role  = aws_iam_role.codebuild.arn
  build_timeout = 180

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = var.codebuild_compute_type
    image                       = var.codebuild_image
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "CODEBUILD"
    privileged_mode             = false

    environment_variable {
      name  = "INVENTORY_MANIFEST"
      value = var.inventory_manifest
    }
    environment_variable {
      name  = "HAULER_ARTIFACT_NAME"
      value = var.hauler_artifact_name
    }
    environment_variable {
      name  = "ARTIFACT_BUCKET"
      value = aws_s3_bucket.artifacts.bucket
    }
    environment_variable {
      name  = "ARTIFACT_PREFIX"
      value = "hauler-bundles"
    }
    environment_variable {
      name  = "DOCKER_CONFIG_JSON_SECRET_ARN"
      value = var.docker_config_json_secret_arn
    }
    environment_variable {
      name  = "AWS_REGION"
      value = var.aws_region
    }
    environment_variable {
      name  = "AWS_DEFAULT_REGION"
      value = var.aws_region
    }
  }

  logs_config {
    cloudwatch_logs {
      group_name = aws_cloudwatch_log_group.codebuild.name
      status     = "ENABLED"
    }
  }

  source {
    type      = "CODEPIPELINE"
    buildspec = "buildspec/hauler-bundle.yml"
  }

  tags = local.common_tags
}
