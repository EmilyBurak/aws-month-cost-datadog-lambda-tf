import boto3
from datetime import datetime, timedelta
from datadog_lambda.metric import lambda_metric


def lambda_handler(event, context):
    # create iam client
    iam = boto3.client("iam")
    # List account alias through the pagination interface
    paginator = iam.get_paginator("list_account_aliases")

    alias = None

    for response in paginator.paginate():
        alias = response["AccountAliases"]

    # create cost explorer client
    client = boto3.client("ce")

    # set metric time range between today and 30 days ago
    start_date = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")
    end_date = datetime.now().strftime("%Y-%m-%d")

    # grab total last 30 days spend
    resp = client.get_cost_and_usage(
        TimePeriod={"Start": start_date, "End": end_date},
        Granularity="MONTHLY",
        Metrics=["UnblendedCost"],
    )
    total_amount = resp["ResultsByTime"][0]["Total"]["UnblendedCost"]["Amount"]

    # emit metric to Datadog as custom metric from serverless function
    lambda_metric(
        "aws_account.last_month_spend",  # metric name
        total_amount,  # metric value
        tags=[f"aws_account: {alias[0]}"],  # associated tag(s)
    )

    return {"statusCode": 200, "body": "success"}
