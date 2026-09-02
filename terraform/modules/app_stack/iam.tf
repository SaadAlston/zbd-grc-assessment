# AI-ASSISTED: EC2 instance role, managed policy attachments and instance profile generated with Claude.

# [SAAD] The module creates its own role rather than using the existing
# AmazonSSMRoleForInstancesQuickSetup in the account. That role is shared and
# I do not own its permission set. A role created here is destroyed with the
# rest of the stack and its permissions are visible in this file.
resource "aws_iam_role" "instance" {
  name = "${var.candidate}-${var.environment}-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = "sts:AssumeRole"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name = "${var.candidate}-${var.environment}-instance-role"
  }
}

# [SAAD] AWS managed policy rather than a hand written one. The CloudWatch
# agent needs PutMetricData, log group and stream creation, and read access to
# its own SSM parameter for configuration. Writing that by hand means tracking
# permission changes as the agent updates. This is one of the cases where the
# managed policy is scoped tightly enough that maintaining a copy costs more
# than it returns.
resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# [SAAD] SSM Managed Instance Core enables Session Manager, which is the SSH
# replacement. Session access authenticates through IAM and is logged, so
# there is no long lived key to rotate. Task 3 builds on this with the State
# Manager association. SSH stays in this build because the assessment requires
# a security group rule for it in Step 5.
resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# [SAAD] This resource was blocked when the module was written. The assessment
# IAM policy granted iam:CreateRole and iam:AttachRolePolicy but not
# iam:CreateInstanceProfile, iam:AddRoleToInstanceProfile or iam:PassRole.
# Isolated with a RunInstances dry run: the call succeeded without an instance
# profile and failed naming iam:PassRole with one. Requested from Thomas
# Montgomery and granted, then re-verified by dry run. The alternative was
# static IAM keys in user data, which writes long lived credentials into
# instance metadata and into Terraform state. Not an acceptable trade for a
# permission that can be granted by asking.
resource "aws_iam_instance_profile" "instance" {
  name = "${var.candidate}-${var.environment}-instance-profile"
  role = aws_iam_role.instance.name

  tags = {
    Name = "${var.candidate}-${var.environment}-instance-profile"
  }
}