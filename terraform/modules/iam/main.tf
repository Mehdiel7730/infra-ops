###############################################################
# modules/iam/main.tf
# EC2 instance role: SSM + S3 (PoLP)
###############################################################

locals {
  name_prefix = "${var.project}-${var.environment}"
}

data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ec2" {
  name               = "${local.name_prefix}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
  tags               = var.tags
}

# SSM Session Manager (replaces bastion SSH for prod)
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# CloudWatch agent
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# S3 access restricted to project bucket only
data "aws_iam_policy_document" "s3_app" {
  statement {
    sid    = "AppBucketAccess"
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:ListBucket",
    ]
    resources = [
      "arn:aws:s3:::${var.app_s3_bucket}",
      "arn:aws:s3:::${var.app_s3_bucket}/*",
    ]
  }
}

resource "aws_iam_role_policy" "s3_app" {
  name   = "${local.name_prefix}-s3-app"
  role   = aws_iam_role.ec2.id
  policy = data.aws_iam_policy_document.s3_app.json
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${local.name_prefix}-instance-profile"
  role = aws_iam_role.ec2.name
  tags = var.tags
}
