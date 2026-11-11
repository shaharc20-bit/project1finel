data "aws_iam_policy_document" "assume" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "builder" {
  statement {
    sid = "FlaskAwsMonitorRead"
    actions = [
      "ec2:DescribeInstances",
      "ec2:DescribeVpcs",
      "ec2:DescribeImages",
      "elasticloadbalancing:DescribeLoadBalancers",
    ]
    resources = ["*"]
  }

  statement {
    sid       = "BootstrapSecrets"
    actions   = ["ssm:GetParameter", "ssm:GetParameters"]
    resources = var.ssm_parameter_arns
  }

  statement {
    sid       = "DecryptSecureStrings"
    actions   = ["kms:Decrypt"]
    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "kms:ViaService"
      values   = ["ssm.${var.region}.amazonaws.com"]
    }
  }

  dynamic "statement" {
    for_each = var.backup_bucket != "" ? [1] : []
    content {
      sid       = "JenkinsBackups"
      actions   = ["s3:PutObject", "s3:GetObject", "s3:ListBucket"]
      resources = ["arn:aws:s3:::${var.backup_bucket}", "arn:aws:s3:::${var.backup_bucket}/jenkins/*"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${var.name}-builder-role"
  assume_role_policy = data.aws_iam_policy_document.assume.json
}

resource "aws_iam_role_policy" "this" {
  name   = "${var.name}-builder"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.builder.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${var.name}-builder-profile"
  role = aws_iam_role.this.name
}
