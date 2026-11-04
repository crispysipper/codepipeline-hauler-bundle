output "pipeline_name" {
  description = "CodePipeline name"
  value       = aws_codepipeline.hauler.name
}

output "pipeline_arn" {
  description = "CodePipeline ARN"
  value       = aws_codepipeline.hauler.arn
}

output "codebuild_project_name" {
  description = "CodeBuild project name"
  value       = aws_codebuild_project.hauler.name
}

output "artifact_bucket" {
  description = "S3 bucket for pipeline artifacts and Hauler hauls"
  value       = aws_s3_bucket.artifacts.bucket
}

output "hauler_s3_prefix" {
  description = "S3 prefix where finished hauls are stored"
  value       = "s3://${aws_s3_bucket.artifacts.bucket}/hauler-bundles/"
}

output "hauler_latest_uri" {
  description = "Stable latest haul URI for bootstrap_hauler_artifact / custom_hauler_artifact"
  value       = "s3://${aws_s3_bucket.artifacts.bucket}/hauler-bundles/${var.hauler_artifact_name}-latest.tar.zst"
}
