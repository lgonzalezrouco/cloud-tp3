# EventBridge rule to schedule Lambda execution every 10 minutes
resource "aws_cloudwatch_event_rule" "newsletter_schedule" {
  name                = "newsletter-lambda-schedule"
  description         = "Trigger newsletter Lambda every 10 minutes"
  schedule_expression = "rate(5 minutes)"
}

# EventBridge target to invoke Lambda function
resource "aws_cloudwatch_event_target" "newsletter_lambda_target" {
  rule      = aws_cloudwatch_event_rule.newsletter_schedule.name
  target_id = "NewsletterLambdaTarget"
  arn       = aws_lambda_function.product_newsletter.arn
  role_arn  = data.aws_iam_role.lab_role.arn
}

# Permission for EventBridge to invoke Lambda function
resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowExecutionFromEventBridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.product_newsletter.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.newsletter_schedule.arn
}

