variable "aws_region" {
  description = "AWS region for CodePipeline / CodeBuild / S3"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Name prefix for pipeline resources"
  type        = string
  default     = "hauler-bundle"
}

variable "environment" {
  description = "Environment label (dev/stage/prod)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "Common resource tags"
  type        = map(string)
  default     = {}
}

variable "github_owner" {
  description = "GitHub org/user that owns the source repository"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "codepipeline-hauler-bundle"
}

variable "github_branch" {
  description = "Branch that triggers the pipeline"
  type        = string
  default     = "main"
}

variable "codestar_connection_arn" {
  description = "Existing CodeStar Connections ARN for GitHub"
  type        = string
}

variable "hauler_artifact_name" {
  description = "Hauler artifact basename (S3 object prefix)"
  type        = string
  default     = "rke2-bootstrap"
}

variable "inventory_manifest" {
  description = "Inventory path(s) relative to repo root"
  type        = string
  default     = "manifests/inventory.yaml"
}

variable "docker_config_json_secret_arn" {
  description = "Optional Secrets Manager ARN holding a Docker config.json for upstream image pulls"
  type        = string
  default     = ""
}

variable "codebuild_compute_type" {
  description = "CodeBuild compute type (haul sync is memory/disk heavy)"
  type        = string
  default     = "BUILD_GENERAL1_LARGE"
}

variable "codebuild_image" {
  description = "CodeBuild environment image"
  type        = string
  default     = "aws/codebuild/amazonlinux-x86_64-standard:5.0"
}
