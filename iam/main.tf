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
  name               = "${var.lambda_name}_servicerole"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}


data "aws_iam_policy_document" "cost_usage_aliases_policy" {
  statement {
    effect    = "Allow"
    actions   = ["ce:GetCostAndUsage"]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "month_cost_lambda_policy" {
  name        = "${var.lambda_name}_policy"
  description = "A policy for the last month's AWS cost polling lambda that allows Cost and Usage get"
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
