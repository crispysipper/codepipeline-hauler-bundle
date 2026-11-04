data "aws_iam_policy_document" "codebuild_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codebuild.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codebuild" {
  name               = "${local.name}-codebuild"
  assume_role_policy = data.aws_iam_policy_document.codebuild_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "codebuild" {
  statement {
    sid = "Logs"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
    resources = ["*"]
  }

  statement {
    sid = "PipelineAndHaulArtifacts"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*",
    ]
  }

  dynamic "statement" {
    for_each = var.docker_config_json_secret_arn != "" ? [1] : []
    content {
      sid = "DockerConfigSecret"
      actions = [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret",
      ]
      resources = [var.docker_config_json_secret_arn]
    }
  }
}

resource "aws_iam_role_policy" "codebuild" {
  name   = "${local.name}-codebuild"
  role   = aws_iam_role.codebuild.id
  policy = data.aws_iam_policy_document.codebuild.json
}

data "aws_iam_policy_document" "codepipeline_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["codepipeline.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "codepipeline" {
  name               = "${local.name}-codepipeline"
  assume_role_policy = data.aws_iam_policy_document.codepipeline_assume.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "codepipeline" {
  statement {
    sid = "S3"
    actions = [
      "s3:GetObject",
      "s3:GetObjectVersion",
      "s3:PutObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.artifacts.arn,
      "${aws_s3_bucket.artifacts.arn}/*",
    ]
  }

  statement {
    sid = "CodeBuild"
    actions = [
      "codebuild:BatchGetBuilds",
      "codebuild:StartBuild",
      "codebuild:BatchGetBuildBatches",
      "codebuild:StartBuildBatch",
    ]
    resources = [aws_codebuild_project.hauler.arn]
  }

  statement {
    sid       = "CodeStarConnection"
    actions   = ["codestar-connections:UseConnection"]
    resources = [var.codestar_connection_arn]
  }
}

resource "aws_iam_role_policy" "codepipeline" {
  name   = "${local.name}-codepipeline"
  role   = aws_iam_role.codepipeline.id
  policy = data.aws_iam_policy_document.codepipeline.json
}
