data "archive_file" "deploy_trigger" {
  type        = "zip"
  source_dir  = "${path.root}/../lambda/deploy-trigger"
  output_path = "${path.module}/lambda_deploy_trigger.zip"
}

resource "aws_lambda_function" "deploy_trigger" {
  function_name    = "three-tier-deploy-trigger"
  role             = aws_iam_role.lambda_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.12"
  filename         = data.archive_file.deploy_trigger.output_path
  source_code_hash = data.archive_file.deploy_trigger.output_base64sha256
  timeout          = 300

  environment {
    variables = {
      WEB_ASG_NAME = aws_autoscaling_group.web.name
      APP_ASG_NAME = aws_autoscaling_group.app.name
      S3_BUCKET    = var.s3_artifact_bucket
      REGION       = var.aws_region
    }
  }

  tags = { Name = "deploy-trigger" }
}
