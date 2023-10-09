output "lambda_cost_iam_role_arn" {
    description = "ARN of the IAM Service Role for the Lambda"
    value = aws_iam_role.month_cost_lambda.arn
}