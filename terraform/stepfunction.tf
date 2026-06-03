resource "aws_sfn_state_machine" "deployment" {
  name     = "three-tier-deployment"
  role_arn = aws_iam_role.sfn_role.arn

  definition = templatefile("${path.root}/../step-function/deployment-flow.json", {
    deploy_lambda_arn = aws_lambda_function.deploy_trigger.arn
  })

  tags = { Name = "three-tier-deployment-sfn" }
}
