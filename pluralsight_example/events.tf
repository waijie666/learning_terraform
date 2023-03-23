resource "aws_cloudwatch_event_rule" "instance_change" {
  name        = "capture-aws-instance-changes"
  description = "Capture AWS instance creation and deletion"

  event_pattern = jsonencode({
    source = ["aws.ec2"]
    detail-type = [
      "EC2 Instance State-change Notification"
    ]
    detail = {
      state = ["pending", "terminated"]
    }
  })
}

resource "aws_cloudwatch_event_target" "sns" {
  rule      = aws_cloudwatch_event_rule.instance_change.name
  target_id = "SendToSNS"
  arn       = aws_sns_topic.sns_catch_all.arn
}

resource "aws_sns_topic" "sns_catch_all" {
  name = "sns_catch_all"
}

resource "aws_sns_topic_subscription" "sns_catch_all_lambda_target" {
  topic_arn = aws_sns_topic.sns_catch_all.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.sns_event_handling.arn
}

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

resource "aws_iam_role" "iam_for_lambda" {
  name               = "iam_for_lambda"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

data "archive_file" "sns_event_handling_payload" {
  type        = "zip"
  source_dir  = "${path.module}/lambda_source_files/python/sns_event_handling/"
  output_path = "${path.module}/payload/sns_event_handling.zip"
}

resource "aws_lambda_function" "sns_event_handling" {
  # If the file is not in the current working directory you will need to include a
  # path.module in the filename.
  filename         = "${path.module}/payload/sns_event_handling.zip"
  function_name    = "sns_event_handling"
  handler          = "lambda_function.lambda_handler"
  role             = aws_iam_role.iam_for_lambda.arn
  source_code_hash = data.archive_file.sns_event_handling_payload.output_base64sha256

  runtime = "python3.9"

  environment {
    variables = {
      foo = "bar"
    }
  }
}

resource "aws_lambda_permission" "allow_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.sns_event_handling.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.sns_catch_all.arn
}