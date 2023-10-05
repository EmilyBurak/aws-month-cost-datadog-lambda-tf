data "aws_iam_policy_document" "assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "month_cost_lambda" {
  name               = "month_cost_lambda_servicerole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


data "aws_iam_policy_document" "cost_usage_aliases_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ce:GetCostAndUsage", "iam:ListAccountAliases"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "month_cost_lambda_policy" {
  name        = "month_cost_lambda_policy"
  description = "A policy for the last month's cost polling lambda that allows Cost and Usage and Account Alias listing"
  policy      = data.aws_iam_policy_document.cost_usage_aliases_policy.json
}

resource "aws_iam_role_policy_attachment" "cost_policy_attach" {
  role       = aws_iam_role.month_cost_lambda.name
  policy_arn = aws_iam_policy.month_cost_lambda_policy.arn
}


resource "aws_iam_role_policy_attachment" "lambda_basic_role_attach" {
  role       = aws_iam_role.month_cost_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# could use a better CI/CD process for the lambda itself on S3 or ECR
# edit .py file locally and reupload for changes for now 
data "archive_file" "cost_lambda_test_zip" {
  type        = "zip"
  source_dir  = "${path.module}/python/"
  output_path = "${path.module}/python/cost_lambda_test.zip"
}

# runs every day, could easily be changed to a different frequency via. rate() expression syntax
resource "aws_cloudwatch_event_rule" "every_day" {
  name                = "every_day_rule"
  description         = "meant to trigger a lambda every day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "cost_lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_day.name
  target_id = "SendToLambda"
  arn       = aws_lambda_function.month_cost_function.arn
}

resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.month_cost_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_day.arn
}

resource "aws_lambda_function" "month_cost_function" {
  filename      = "${path.module}/python/cost_lambda_test.zip"
  function_name = "monthly_cost_lambda"
  role          = aws_iam_role.month_cost_lambda.arn
  runtime       = "python3.8"
  depends_on    = [aws_iam_role_policy_attachment.lambda_basic_role_attach, aws_iam_role_policy_attachment.cost_policy_attach]
  timeout       = 10 # increases as this is currently running slow for reasons that need to be debugged 
  layers = [
    "arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Extension:49",
    "arn:aws:lambda:us-east-1:464622532012:layer:Datadog-Python38:80"
  ]

  handler = "datadog_lambda.handler.handler"

  environment {
    variables = {
      DD_SITE                      = "datadoghq.com"
      DD_API_KEY                   = var.dd_api_key # pass in at runtime or through GH action secret
      DD_CAPTURE_LAMBDA_PAYLOAD    = "false"
      DD_FLUSH_TO_LOG              = "true"
      DD_MERGE_XRAY_TRACES         = "false"
      DD_TRACE_ENABLED             = "true"
      DD_LAMBDA_HANDLER            = "app.lambda_handler"
      DD_SERVERLESS_APPSEC_ENABLED = "false"
    }
  }
  tags = {
    "dd_sls_ci" = "v2.21.1"
  }
  tags_all = {
    "dd_sls_ci" = "v2.21.1"
  }
}