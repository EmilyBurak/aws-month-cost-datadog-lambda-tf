# aws-month-cost-datadog-lambda-tf

## Introduction and Goals

While the UI of AWS Cost Explorer is very useful and intuitive, I wanted granular integration of metrics derived from it for Datadog integration.
Specifically as a proof of concept I wanted to pull the **last 30 days of unblended cost in total** from an account and push that metric to DD.
This ended up best achieved through the boto3 SDK, with Python and the boto library being familiar. It's important to build this out to be
modular and so Terraform became especially important for transferring to IaC and down the line allowing for this to be used by others towards
their own related use cases.

## Technologies used

- boto3
- Lambda for running the boto3 code in a serverless fashion
- EventBridge for daily Lambda triggering
- IAM for the inter-service permissions required
- Datadog for monitoring and dashboarding out the results of the lambda

## How It Works

The core code is in `/python/app.py`, which is zipped by **Terraform** and used by **Lambda**. It daily polls the total last 30 days of spend in unblended total cost amount for an AWS account along with the account's alias and surfaces that information to **Datadog** as a custom metric of `aws_account.last_month_spend` via. the [Datadog Lambda Library for Python](https://github.com/DataDog/datadog-lambda-python).
**This timeframe and the schedule the lambda runs on through EventBridge(once daily) can of course be tweaked for different uses.**
**IAM** is used to make sure services(Lambda and **EventBridge** using a **CloudWatch Event Rule**) can speak to each other and other services(such as **Cost Explorer** and IAM to grab the account alias), commissioning the `month_cost_lambda_servicerole` role with the attached `month_cost_lambda_policy` and the `AWSLambdaBasicExecutionRole` AWS managed policy to provide the appropriate permissions. Currently a GitHub Action to automate CI/CD deployment
of the attendant resources is in working stages, triggered by `workflow_dispatch` as it's being figured out.

## How To Use

- Run Terraform code included with the core TF workflow(`terraform init` --> `terraform plan` --> `terraform apply`)
- Set up Datadog infra to accompany(monitor, alerting, dashboarding, etc. -- mean to add these to the Terraform code)

## Lessons Learned / Observations

- The Datadog setup was a little confusing from their documentation but smooth to instrument once the proper route was found (monitoring the serverless
  function and then emitting a custom metric from it.) There's a bunch of different ways to tackle this in DD and it wasn't entirely clear which was best
  or most viable for the use case at first.
- I hadn't written a Lambda in a long while, and had just gotten back into writing Python and boto3 for [Generating AWS Terraform import blocks](https://github.com/EmilyBurak/generate-aws-tf-import-blocks) so that was fun if a bit bumpy to figure out at first how the pieces fit together with the DD lambda
  layer/library. The Cost Explorer API can get really complex around matters such as pricing(due to the intricacies of AWS pricing) but it proved pretty
  clean to work with for this purpose.
- This was my first time scheduling a Lambda using EventBridge and I found it to be rather seamless and easy to set up, including the Terraform.

## TO DO

- Add tags for both AWS and Datadog
- Set up proper remote state
- Add DD dashboarding to TF code
- Make more modular the time window of the data polled, and/or frequency
- Split off all the IAM in `main.tf` into its own module

## Resources

- https://docs.datadoghq.com/serverless/installation/python/
- https://spacelift.io/blog/terraform-aws-lambda
