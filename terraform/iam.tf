data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "app" {
  name               = "${local.name}-ec2-role"
  description        = "EC2 role for Systems Manager Session Manager access"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json

  tags = {
    Name = "${local.name}-ec2-role"
  }
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.app.name
  policy_arn = local.ssm_policy_arn
}

resource "aws_iam_instance_profile" "app" {
  name = "${local.name}-ec2-profile"
  role = aws_iam_role.app.name

  tags = {
    Name = "${local.name}-ec2-profile"
  }
}
