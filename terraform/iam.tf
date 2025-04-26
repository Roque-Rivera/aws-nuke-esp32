resource "aws_iam_role" "lambda_role" {
  name = "${var.project_name}-lambda-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_nuke_policy" {
  name        = "${var.project_name}-lambda-policy"
  description = "Policy for AWS Nuke Button Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      },
      {
        Effect = "Allow"
        Action = [
          "ec2:CreateNetworkInterface",
          "ec2:DescribeNetworkInterfaces",
          "ec2:DeleteNetworkInterface"
        ]
        Resource = ["*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject"
        ]
        Resource = ["${aws_s3_bucket.nuke_config.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = "*"  # This is dangerous but necessary for aws-nuke!
        Resource = "*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = var.aws_account_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_nuke" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_nuke_policy.arn
}